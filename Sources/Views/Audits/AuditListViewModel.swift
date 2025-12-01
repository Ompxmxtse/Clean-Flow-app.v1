import Foundation
import FirebaseFirestore

@MainActor
class AuditListViewModel: ObservableObject {
    @Published var audits: [Audit] = []
    @Published var filteredAudits: [Audit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?
    
    // Computed properties for filters
    var uniqueUsers: [String] {
        Array(Set(audits.map { $0.auditorName })).sorted()
    }
    
    var uniqueRooms: [String] {
        Array(Set(audits.map { $0.roomName })).sorted()
    }
    
    deinit {
        listenerRegistration?.remove()
    }
    
    func loadAudits() {
        isLoading = true
        errorMessage = nil
        
        listenerRegistration = db.collection("audits")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                let audits = snapshot?.documents.compactMap { document in
                    try? document.data(as: Audit.self)
                } ?? []
                
                self.audits = audits
                self.filteredAudits = audits
                self.isLoading = false
            }
    }
    
    func applyFilters(
        dateFilter: AuditListView.DateFilter,
        userFilter: String,
        roomFilter: String,
        searchText: String
    ) {
        var filtered = audits
        
        // Apply date filter
        let calendar = Calendar.current
        let now = Date()
        
        switch dateFilter {
        case .today:
            filtered = filtered.filter { calendar.isDate($0.createdAt, inSameDayAs: now) }
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            filtered = filtered.filter { $0.createdAt >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            filtered = filtered.filter { $0.createdAt >= monthAgo }
        case .all:
            break
        }
        
        // Apply user filter
        if !userFilter.isEmpty {
            filtered = filtered.filter { $0.auditorName == userFilter }
        }
        
        // Apply room filter
        if !roomFilter.isEmpty {
            filtered = filtered.filter { $0.roomName == roomFilter }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            filtered = filtered.filter { audit in
                audit.auditorName.localizedCaseInsensitiveContains(searchText) ||
                audit.roomName.localizedCaseInsensitiveContains(searchText) ||
                audit.id.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredAudits = filtered
    }
    
    func exportAudits(format: ExportOptionsView.ExportFormat) {
        // Implementation for export functionality
        switch format {
        case .csv:
            exportAsCSV()
        case .pdf:
            exportAsPDF()
        }
    }
    
    private func exportAsCSV() {
        let csvString = generateCSVString()
        // Save to file or share
    }
    
    private func exportAsPDF() {
        // PDF export implementation
    }
    
    private func generateCSVString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        var csv = "ID,Auditor,Room,Compliance Score,Status,Created At,Has Exceptions\n"
        
        for audit in filteredAudits {
            let escapedAuditor = "\"\(audit.auditorName.replacingOccurrences(of: "\"", with: "\"\""))\""
            let escapedRoom = "\"\(audit.roomName.replacingOccurrences(of: "\"", with: "\"\""))\""
            
            let row = [
                audit.id,
                escapedAuditor,
                escapedRoom,
                String(audit.complianceScore),
                audit.status.rawValue,
                dateFormatter.string(from: audit.createdAt),
                audit.hasExceptions ? "Yes" : "No"
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
}

// MARK: - Audit Model
struct Audit: Codable, Identifiable {
    let id: String
    let auditorId: String
    let auditorName: String
    let roomId: String
    let roomName: String
    let cleaningRunId: String
    let complianceScore: Double
    let status: AuditStatus
    let hasExceptions: Bool
    let exceptionCount: Int
    let createdAt: Date
    
    enum AuditStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case failed = "failed"
    }
}

extension Audit {
    static var mock: Audit {
        Audit(
            id: "audit-1",
            auditorId: "user-1",
            auditorName: "Dr. Sarah Johnson",
            roomId: "room-1",
            roomName: "Operating Room 1",
            cleaningRunId: "run-1",
            complianceScore: 95.0,
            status: .completed,
            hasExceptions: false,
            exceptionCount: 0,
            createdAt: Date().addingTimeInterval(-3600)
        )
    }
}
