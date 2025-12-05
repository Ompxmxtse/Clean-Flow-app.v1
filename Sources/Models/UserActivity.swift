import Foundation
import SwiftUI

// MARK: - UserActivity Model
// Single canonical definition used by StaffDetailViewModel, StaffDetailView, and UserDetailView

struct UserActivity: Identifiable {
    let id: String
    let type: ActivityType
    let description: String
    let timestamp: Date
    let areaName: String

    enum ActivityType {
        case cleaningCompleted
        case protocolStarted
        case auditPassed
        case auditFailed
        case login
    }

    var icon: String {
        switch type {
        case .cleaningCompleted: return "checkmark.circle.fill"
        case .protocolStarted: return "play.circle.fill"
        case .auditPassed: return "shield.checkered"
        case .auditFailed: return "xmark.circle.fill"
        case .login: return "person.crop.circle.badge.checkmark"
        }
    }

    var color: Color {
        switch type {
        case .cleaningCompleted, .auditPassed: return Color(red: 100/255, green: 255/255, blue: 100/255)
        case .protocolStarted, .login: return Color(red: 43/255, green: 203/255, blue: 255/255)
        case .auditFailed: return Color(red: 255/255, green: 100/255, blue: 100/255)
        }
    }
}

// MARK: - Mock Data
extension UserActivity {
    static var mockActivities: [UserActivity] {
        [
            UserActivity(
                id: "1",
                type: .cleaningCompleted,
                description: "Completed OR Suite cleaning",
                timestamp: Date().addingTimeInterval(-3600),
                areaName: "Operating Room 3"
            ),
            UserActivity(
                id: "2",
                type: .protocolStarted,
                description: "Started ICU Protocol",
                timestamp: Date().addingTimeInterval(-7200),
                areaName: "ICU Ward A"
            ),
            UserActivity(
                id: "3",
                type: .auditPassed,
                description: "Passed compliance audit",
                timestamp: Date().addingTimeInterval(-86400),
                areaName: "Emergency Bay 1"
            )
        ]
    }
}
