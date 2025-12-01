import Foundation

// MARK: - Mock Data

struct MockData {
    static let users: [User] = [
        User(
            id: "user-1",
            email: "john.doe@hospital.com",
            name: "John Doe",
            role: .cleaner,
            department: "Surgery",
            isActive: true,
            createdAt: Date().addingTimeInterval(-86400 * 30),
            lastLogin: Date().addingTimeInterval(-3600)
        ),
        User(
            id: "user-2",
            email: "jane.smith@hospital.com",
            name: "Jane Smith",
            role: .supervisor,
            department: "ICU",
            isActive: true,
            createdAt: Date().addingTimeInterval(-86400 * 60),
            lastLogin: Date().addingTimeInterval(-1800)
        ),
        User(
            id: "user-3",
            email: "mike.chen@hospital.com",
            name: "Mike Chen",
            role: .auditor,
            department: "Quality",
            isActive: true,
            createdAt: Date().addingTimeInterval(-86400 * 90),
            lastLogin: Date().addingTimeInterval(-7200)
        ),
        User(
            id: "user-4",
            email: "sarah.johnson@hospital.com",
            name: "Dr. Sarah Johnson",
            role: .admin,
            department: "Administration",
            isActive: true,
            createdAt: Date().addingTimeInterval(-86400 * 365),
            lastLogin: Date().addingTimeInterval(-900)
        ),
        User(
            id: "user-5",
            email: "lisa.anderson@hospital.com",
            name: "Lisa Anderson",
            role: .cleaner,
            department: "Emergency",
            isActive: false,
            createdAt: Date().addingTimeInterval(-86400 * 45),
            lastLogin: Date().addingTimeInterval(-86400 * 2)
        )
    ]
}
