import Foundation
import FirebaseFirestore
import Combine

@MainActor
class StaffListViewModel: ObservableObject {
    @Published var staff: [User] = []
    @Published var filteredStaff: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Stats
    @Published var totalStaff = 0
    @Published var activeToday = 0
    @Published var onLeave = 0
    @Published var newThisMonth = 0
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    private var loadTask: Task<Void, Never>?
    
    deinit {
        loadTask?.cancel()
        listenerRegistration?.remove()
    }
    
    func loadStaff() {
        loadTask?.cancel()
        isLoading = true
        errorMessage = nil
        
        loadTask = Task { [weak self] in
            guard let self = self else { return }
            
            self.listenerRegistration = db.collection("users")
                .order(by: "name")
                .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                let staff = snapshot?.documents.compactMap { document in
                    try? document.data(as: User.self)
                } ?? []
                
                self.staff = staff
                self.filteredStaff = staff
                self.calculateStats()
                self.isLoading = false
            }
    }
    
    func applyFilters(role: User.UserRole?, searchText: String) {
        var filtered = staff
        
        // Apply role filter
        if let role = role {
            filtered = filtered.filter { $0.role == role }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            filtered = filtered.filter { user in
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText) ||
                user.department.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredStaff = filtered
    }
    
    private func calculateStats() {
        totalStaff = staff.count
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let monthStart = calendar.dateInterval(of: .month, for: Date())?.start ?? today
        
        activeToday = staff.filter { user in
            calendar.isDate(user.lastLogin, inSameDayAs: today) && user.isActive
        }.count
        
        onLeave = staff.filter { !$0.isActive }.count
        
        newThisMonth = staff.filter { user in
            user.createdAt >= monthStart
        }.count
    }
}
