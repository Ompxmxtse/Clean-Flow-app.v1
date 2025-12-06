import Foundation
import SwiftUI

// MARK: - UserActivityType

enum UserActivityType: String, Codable, CaseIterable {
    case cleaningCompleted
    case protocolStarted
    case auditPassed
    case auditFailed
    case login
    case logout
    case profileUpdated
}

// MARK: - UserActivity Model

struct UserActivity: Identifiable, Codable {
    var id: String = UUID().uuidString
    var userId: String
    var type: UserActivityType
    var message: String
    var timestamp: Date
    var relatedEntityId: String?
    var relatedEntityType: String? // "audit", "protocol", "cleaningRun", etc.

    // MARK: - Computed Properties for UI

    var icon: String {
        switch type {
        case .cleaningCompleted: return "checkmark.circle.fill"
        case .protocolStarted: return "play.circle.fill"
        case .auditPassed: return "shield.checkered"
        case .auditFailed: return "xmark.circle.fill"
        case .login: return "person.crop.circle.badge.checkmark"
        case .logout: return "rectangle.portrait.and.arrow.right"
        case .profileUpdated: return "person.crop.circle.badge.pencil"
        }
    }

    var color: Color {
        switch type {
        case .cleaningCompleted, .auditPassed:
            return Color(red: 100/255, green: 255/255, blue: 100/255)
        case .protocolStarted, .login:
            return Color(red: 43/255, green: 203/255, blue: 255/255)
        case .auditFailed:
            return Color(red: 255/255, green: 100/255, blue: 100/255)
        case .logout, .profileUpdated:
            return Color(red: 138/255, green: 77/255, blue: 255/255)
        }
    }

    // Backwards compatibility alias
    var description: String { message }
    var areaName: String { relatedEntityType ?? "" }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case type
        case message
        case timestamp
        case relatedEntityId
        case relatedEntityType
    }

    // MARK: - Initializers

    init(
        id: String = UUID().uuidString,
        userId: String,
        type: UserActivityType,
        message: String,
        timestamp: Date = Date(),
        relatedEntityId: String? = nil,
        relatedEntityType: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.message = message
        self.timestamp = timestamp
        self.relatedEntityId = relatedEntityId
        self.relatedEntityType = relatedEntityType
    }

    // Legacy initializer for backwards compatibility
    init(
        id: String,
        type: UserActivityType,
        description: String,
        timestamp: Date,
        areaName: String
    ) {
        self.id = id
        self.userId = ""
        self.type = type
        self.message = description
        self.timestamp = timestamp
        self.relatedEntityId = nil
        self.relatedEntityType = areaName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        userId = try container.decodeIfPresent(String.self, forKey: .userId) ?? ""
        type = try container.decode(UserActivityType.self, forKey: .type)
        message = try container.decodeIfPresent(String.self, forKey: .message) ?? ""
        timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        relatedEntityId = try container.decodeIfPresent(String.self, forKey: .relatedEntityId)
        relatedEntityType = try container.decodeIfPresent(String.self, forKey: .relatedEntityType)
    }
}

// MARK: - Mock Data

extension UserActivity {
    static var mockActivities: [UserActivity] {
        [
            UserActivity(
                id: "1",
                userId: "user-1",
                type: .cleaningCompleted,
                message: "Completed OR Suite cleaning",
                timestamp: Date().addingTimeInterval(-3600),
                relatedEntityId: "cleaning-run-1",
                relatedEntityType: "Operating Room 3"
            ),
            UserActivity(
                id: "2",
                userId: "user-1",
                type: .protocolStarted,
                message: "Started ICU Protocol",
                timestamp: Date().addingTimeInterval(-7200),
                relatedEntityId: "protocol-1",
                relatedEntityType: "ICU Ward A"
            ),
            UserActivity(
                id: "3",
                userId: "user-1",
                type: .auditPassed,
                message: "Passed compliance audit",
                timestamp: Date().addingTimeInterval(-86400),
                relatedEntityId: "audit-1",
                relatedEntityType: "Emergency Bay 1"
            ),
            UserActivity(
                id: "4",
                userId: "user-1",
                type: .login,
                message: "Logged in from iOS device",
                timestamp: Date().addingTimeInterval(-90000)
            )
        ]
    }
}
