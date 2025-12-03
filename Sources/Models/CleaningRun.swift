import Foundation

struct CleaningRun: Codable, Identifiable {
    let id: String
    var protocolId: String
    var protocolName: String
    var cleanerId: String
    var cleanerName: String
    var areaId: String
    var areaName: String
    var startTime: Date
    var endTime: Date?
    var status: CleaningStatus
    var verificationMethod: VerificationMethod
    var qrCode: String?
    var nfcTag: String?
    var steps: [CompletedStep]
    var notes: String?
    var auditorId: String?
    var auditorName: String?
    var complianceScore: Double?
    var createdAt: Date

    // Legacy support for simplified API
    var userId: String { cleanerId }
    var roomId: String { areaId }
    var stepsCompleted: [String] { steps.filter { $0.completed }.map { $0.stepId } }
    var completedAt: Date { endTime ?? createdAt }
    var exceptions: [CleaningException] { [] }

    // Computed properties for UI compatibility
    var roomName: String? { areaName }
}

enum CleaningStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case verified = "verified"
    case failed = "failed"
}

enum VerificationMethod: String, Codable, CaseIterable {
    case manual = "manual"
    case qrCode = "qr_code"
    case nfc = "nfc"
    case supervisor = "supervisor"
}

struct CompletedStep: Codable, Identifiable {
    let id: String
    let stepId: String
    let name: String
    var completed: Bool
    var completedAt: Date?
    var completedBy: String?
    var notes: String?
    var checklistItems: [CompletedChecklistItem]
}

struct CompletedChecklistItem: Codable, Identifiable {
    let id: String
    let item: ChecklistItem
    var completed: Bool
    var completedAt: Date?
}

struct ChecklistItem: Codable, Identifiable {
    let id: String
    let text: String
    let isRequired: Bool
}

struct CleaningException: Codable, Identifiable {
    let id: String
    let stepId: String
    let reason: String
    let reportedAt: Date
    let reportedBy: String
    let approvedBy: String?
    let approvedAt: Date?
    
    enum ExceptionType: String, Codable, CaseIterable {
        case missed = "missed"
        case incomplete = "incomplete"
        case delayed = "delayed"
        case equipmentIssue = "equipment_issue"
        case other = "other"
    }
}

extension CleaningRun {
    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var isOverdue: Bool {
        return false
    }

    static var mock: CleaningRun {
        CleaningRun(
            id: "run-1",
            protocolId: "protocol-1",
            protocolName: "OR Suite Protocol A",
            cleanerId: "user-1",
            cleanerName: "John Doe",
            areaId: "room-1",
            areaName: "Operating Room 1",
            startTime: Date().addingTimeInterval(-3600),
            endTime: Date().addingTimeInterval(-1800),
            status: .completed,
            verificationMethod: .qrCode,
            qrCode: "CF-AREA-room-1-PROTOCOL-protocol-1",
            nfcTag: nil,
            steps: [
                CompletedStep(
                    id: "completed-step-1",
                    stepId: "step-1",
                    name: "Surface Disinfection",
                    completed: true,
                    completedAt: Date().addingTimeInterval(-2700),
                    completedBy: "John Doe",
                    notes: nil,
                    checklistItems: [
                        CompletedChecklistItem(
                            id: "completed-item-1",
                            item: ChecklistItem(id: "item-1", text: "Wipe all surfaces", isRequired: true),
                            completed: true,
                            completedAt: Date().addingTimeInterval(-2700)
                        )
                    ]
                ),
                CompletedStep(
                    id: "completed-step-2",
                    stepId: "step-2",
                    name: "Equipment Cleaning",
                    completed: true,
                    completedAt: Date().addingTimeInterval(-2100),
                    completedBy: "John Doe",
                    notes: nil,
                    checklistItems: []
                )
            ],
            notes: nil,
            auditorId: nil,
            auditorName: nil,
            complianceScore: 100.0,
            createdAt: Date().addingTimeInterval(-3600)
        )
    }
}
