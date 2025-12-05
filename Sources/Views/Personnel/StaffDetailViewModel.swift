import Foundation
import FirebaseFirestore
import Combine
import SwiftUI

@MainActor
class StaffDetailViewModel: ObservableObject {
    @Published var cyclesToday = 0
    @Published var averageTime = 0
    @Published var complianceRate = 0
    @Published var monthlyCycles = 0
    @Published var recentActivity: [UserActivity] = []
    
    private let user: User
    private let db = Firestore.firestore()
    private var task: Task<Void, Never>?
    
    deinit {
        task?.cancel()
    }
    
    init(user: User) {
        self.user = user
    }
    
    func loadActivityData() {
        Task {
            await fetchCleaningStats()
            await fetchRecentActivity()
        }
    }
    
    private func fetchCleaningStats() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? today
        
        do {
            // Today's runs
            let todayRuns = try await db.collection("runs")
                .whereField("userId", isEqualTo: user.id)
                .whereField("completedAt", isGreaterThanOrEqualTo: today)
                .getDocuments()
            
            cyclesToday = todayRuns.documents.count
            
            // Monthly runs
            let monthlyRuns = try await db.collection("runs")
                .whereField("userId", isEqualTo: user.id)
                .whereField("completedAt", isGreaterThanOrEqualTo: monthStart)
                .getDocuments()
            
            monthlyCycles = monthlyRuns.documents.count
            
            // Calculate compliance rate
            let allRuns = try await db.collection("runs")
                .whereField("userId", isEqualTo: user.id)
                .order(by: "completedAt", descending: true)
                .limit(to: 100)
                .getDocuments()
            
            let totalCompliance = allRuns.documents.reduce(0) { sum, document in
                guard let data = document.data() as? [String: Any],
                      let stepsCompleted = data["stepsCompleted"] as? [String],
                      let exceptions = data["exceptions"] as? [[String: Any]] else {
                    return sum
                }
                
                let totalSteps = stepsCompleted.count + exceptions.count
                let compliance = totalSteps > 0 ? (Double(stepsCompleted.count) / Double(totalSteps)) * 100 : 0
                return sum + compliance
            }
            
            complianceRate = allRuns.documents.isEmpty ? 0 : Int(totalCompliance / Double(allRuns.documents.count))
            averageTime = 45 // Placeholder - would calculate from protocol data
            
        } catch {
            // Handle error appropriately in production
        }
    }
    
    private func fetchRecentActivity() async {
        do {
            let runs = try await db.collection("runs")
                .whereField("userId", isEqualTo: user.id)
                .order(by: "completedAt", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            recentActivity = runs.documents.compactMap { document in
                guard let data = document.data() as? [String: Any],
                      let completedAt = data["completedAt"] as? Timestamp,
                      let roomId = data["roomId"] as? String else {
                    return nil
                }
                
                return UserActivity(
                    id: document.documentID,
                    type: .cleaningCompleted,
                    description: "Completed cleaning cycle",
                    timestamp: completedAt.dateValue(),
                    areaName: "Room \(roomId.suffix(4))"
                )
            }
            
        } catch {
            // Handle error appropriately in production
        }
    }
}

// MARK: - User Activity Model
fileprivate struct UserActivity: Identifiable {
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
