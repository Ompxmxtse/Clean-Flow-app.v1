import Foundation

// MARK: - Data Source Protocol

protocol UserDataSource {
    var users: [User] { get }
}

// MARK: - Mock Data Source

struct MockUserDataSource: UserDataSource {
    var users: [User] {
        MockData.users
    }
}

// MARK: - Production Data Source (placeholder)

struct ProductionUserDataSource: UserDataSource {
    var users: [User] {
        // This would be replaced with actual Firebase/Firestore calls
        []
    }
}
