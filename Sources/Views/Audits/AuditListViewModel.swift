import Foundation
import FirebaseFirestore
import Combine

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
                    do {
                        let data = document.data()
                        
                        let audit = Audit(
                            id: document.documentID,
                            cleaningRunId: data["cleaningRunId"] as? String ?? "",
                            auditorName: data["auditorName"] as? String ?? "",
                            auditDate: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                            score: data["complianceScore"] as? Double ?? 0.0,
                            status: AuditStatus(rawValue: (data["status"] as? String) ?? "pending") ?? .pending,
                            findings: data["findings"] as? [String] ?? [],
                            recommendations: data["recommendations"] as? [String] ?? [],
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                        return audit
                    } catch {
                        print("Error decoding audit: \(error)")
                        return nil
                    }
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
            filtered = filtered.filter { calendar.isDate($0.auditDate, inSameDayAs: now) }
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            filtered = filtered.filter { $0.auditDate >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            filtered = filtered.filter { $0.auditDate >= monthAgo }
        case .all:
            break
        }
        
        // Apply user filter
        if !userFilter.isEmpty {
            filtered = filtered.filter { $0.auditorName == userFilter }
        }
        
        // Apply room filter (using cleaningRunId as proxy)
        if !roomFilter.isEmpty {
            filtered = filtered.filter { $0.cleaningRunId.contains(roomFilter) }
        }
        
        // Apply search text
        if !searchText.isEmpty {
            filtered = filtered.filter { audit in
                audit.auditorName.localizedCaseInsensitiveContains(searchText) ||
                audit.cleaningRunId.localizedCaseInsensitiveContains(searchText) ||
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
        
        var csv = "ID,Auditor,Cleaning Run ID,Score,Status,Audit Date,Created At\n"
        
        for audit in filteredAudits {
            let escapedAuditor = "\"\(audit.auditorName.replacingOccurrences(of: "\"", with: "\"\""))\""
            
            let row = [
                audit.id,
                escapedAuditor,
                audit.cleaningRunId,
                String(audit.score),
                audit.status.rawValue,
                dateFormatter.string(from: audit.auditDate),
                dateFormatter.string(from: audit.createdAt)
            ].joined(separator: ",")
            
            csv += row + "\n"
        }
        
        return csv
    }
}

extension Audit {
    static var mock: Audit {
        Audit(
            id: "audit-1",
            cleaningRunId: "run-1",
            auditorName: "Dr. Sarah Johnson",
            auditDate: Date().addingTimeInterval(-3600),
            score: 95.0,
            status: .completed,
            findings: ["All areas properly cleaned", "No contamination found"],
            recommendations: ["Continue current cleaning protocol", "Schedule next audit in 2 weeks"],
            createdAt: Date().addingTimeInterval(-3600)
        )
    }
}
