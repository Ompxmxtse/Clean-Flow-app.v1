import Foundation

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let role: UserRole
    let department: String
    let isActive: Bool
    let createdAt: Date
    let lastLogin: Date
    
    enum UserRole: String, Codable, CaseIterable {
        case admin = "admin"
        case supervisor = "supervisor"
        case cleaner = "cleaner"
        case auditor = "auditor"
    }
}

extension User {
    static var mock: User {
        User(
            id: "mock-id",
            email: "cleaner@hospital.com",
            name: "John Doe",
            role: .cleaner,
            department: "Surgery",
            isActive: true,
            createdAt: Date(),
            lastLogin: Date()
        )
    }
}
