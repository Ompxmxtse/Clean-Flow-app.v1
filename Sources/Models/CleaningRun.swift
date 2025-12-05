import Foundation

// MARK: - Verification Method
enum VerificationMethod: String, Codable, CaseIterable {
    case manual = "manual"
    case qrCode = "qr_code"
    case nfc = "nfc"
    case supervisor = "supervisor"
}

// MARK: - Cleaning Status
enum CleaningStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case verified = "verified"
    case failed = "failed"
}

// MARK: - Checklist Item
struct ChecklistItem: Codable, Identifiable {
    let id: String
    let text: String
    let isRequired: Bool

    init(id: String, text: String, isRequired: Bool = false) {
        self.id = id
        self.text = text
        self.isRequired = isRequired
    }
}

// MARK: - Completed Checklist Item
struct CompletedChecklistItem: Codable, Identifiable {
    let id: String
    let item: ChecklistItem
    var completed: Bool
    var completedAt: Date?

    init(id: String, item: ChecklistItem, completed: Bool = false, completedAt: Date? = nil) {
        self.id = id
        self.item = item
        self.completed = completed
        self.completedAt = completedAt
    }
}

// MARK: - Completed Step
struct CompletedStep: Codable, Identifiable {
    let id: String
    let stepId: String
    let name: String
    var completed: Bool
    var completedAt: Date?
    var completedBy: String?
    var notes: String?
    var checklistItems: [CompletedChecklistItem]

    init(id: String, stepId: String, name: String, completed: Bool = false, completedAt: Date? = nil, completedBy: String? = nil, notes: String? = nil, checklistItems: [CompletedChecklistItem] = []) {
        self.id = id
        self.stepId = stepId
        self.name = name
        self.completed = completed
        self.completedAt = completedAt
        self.completedBy = completedBy
        self.notes = notes
        self.checklistItems = checklistItems
    }
}

// MARK: - Cleaning Run
struct CleaningRun: Codable, Identifiable {
    let id: String
    let protocolId: String
    let protocolName: String
    let cleanerId: String
    let cleanerName: String
    let areaId: String
    let areaName: String
    let startTime: Date
    var endTime: Date?
    var status: CleaningStatus
    let verificationMethod: VerificationMethod
    let qrCode: String?
    let nfcTag: String?
    var steps: [CompletedStep]
    var notes: String?
    var auditorId: String?
    var auditorName: String?
    var complianceScore: Double?
    let createdAt: Date

    init(id: String, protocolId: String, protocolName: String, cleanerId: String, cleanerName: String, areaId: String, areaName: String, startTime: Date, endTime: Date? = nil, status: CleaningStatus = .pending, verificationMethod: VerificationMethod = .manual, qrCode: String? = nil, nfcTag: String? = nil, steps: [CompletedStep] = [], notes: String? = nil, auditorId: String? = nil, auditorName: String? = nil, complianceScore: Double? = nil, createdAt: Date = Date()) {
        self.id = id
        self.protocolId = protocolId
        self.protocolName = protocolName
        self.cleanerId = cleanerId
        self.cleanerName = cleanerName
        self.areaId = areaId
        self.areaName = areaName
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.verificationMethod = verificationMethod
        self.qrCode = qrCode
        self.nfcTag = nfcTag
        self.steps = steps
        self.notes = notes
        self.auditorId = auditorId
        self.auditorName = auditorName
        self.complianceScore = complianceScore
        self.createdAt = createdAt
    }
}

// MARK: - Cleaning Exception
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

// MARK: - CleaningRun Extensions
extension CleaningRun {
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }

    var isOverdue: Bool {
        return status == .inProgress && Date().timeIntervalSince(startTime) > 7200 // 2 hours
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
            startTime: Date().addingTimeInterval(-1800),
            endTime: Date(),
            status: .completed,
            verificationMethod: .qrCode,
            qrCode: "CF-AREA-room-1-PROTOCOL-protocol-1",
            nfcTag: nil,
            steps: [
                CompletedStep(
                    id: "cs-1",
                    stepId: "step-1",
                    name: "Surface Disinfection",
                    completed: true,
                    completedAt: Date().addingTimeInterval(-1200),
                    completedBy: "John Doe",
                    notes: nil,
                    checklistItems: [
                        CompletedChecklistItem(
                            id: "cci-1",
                            item: ChecklistItem(id: "ci-1", text: "Wipe all surfaces", isRequired: true),
                            completed: true,
                            completedAt: Date().addingTimeInterval(-1200)
                        )
                    ]
                )
            ],
            notes: nil,
            auditorId: nil,
            auditorName: nil,
            complianceScore: 100.0,
            createdAt: Date().addingTimeInterval(-1800)
        )
    }
}
