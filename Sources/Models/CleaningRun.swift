import Foundation

struct CleaningRun: Codable, Identifiable {
    let id: String
    let userId: String
    let protocolId: String
    let roomId: String
    let stepsCompleted: [String]
    let completedAt: Date
    let exceptions: [CleaningException]
    
    // Computed properties for UI compatibility
    var protocolName: String? {
        // This would be fetched from protocol collection
        return nil
    }
    
    var cleanerName: String? {
        // This would be fetched from user collection
        return nil
    }
    
    var roomName: String? {
        // This would be fetched from room collection
        return nil
    }
    
    var status: CleaningStatus {
        return completedAt > Date().addingTimeInterval(-3600) ? .completed : .verified
    }
    
    var complianceScore: Double? {
        let totalSteps = stepsCompleted.count + exceptions.count
        guard totalSteps > 0 else { return 0 }
        return (Double(stepsCompleted.count) / Double(totalSteps)) * 100
    }
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
        // Duration would be calculated from protocol start time to completedAt
        return 0 // Placeholder
    }
    
    var isOverdue: Bool {
        // This computed property may not be applicable for completed runs
        // Consider removing or renaming based on actual business requirements
        return false
    }
    
    static var mock: CleaningRun {
        CleaningRun(
            id: "run-1",
            userId: "user-1",
            protocolId: "protocol-1",
            roomId: "room-1",
            stepsCompleted: ["step-1", "step-2", "step-3"],
            completedAt: Date().addingTimeInterval(-1800),
            exceptions: [
                CleaningException(
                    id: "exception-1",
                    stepId: "step-4",
                    reason: "Equipment malfunction - disinfectant sprayer not working",
                    reportedAt: Date().addingTimeInterval(-1900),
                    reportedBy: "John Doe",
                    approvedBy: "Jane Smith",
                    approvedAt: Date().addingTimeInterval(-1850)
                )
            ]
        )
    }
}
