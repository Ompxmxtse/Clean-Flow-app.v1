import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift
import Combine

@MainActor
class AuditListViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var audits: [Audit] = []
    @Published var filteredAudits: [Audit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Computed Properties

    var uniqueUsers: [String] {
        Array(Set(audits.map { $0.auditorName })).sorted()
    }

    var uniqueRooms: [String] {
        Array(Set(audits.map { $0.roomName })).filter { !$0.isEmpty }.sorted()
    }

    // MARK: - Private Properties

    private let db = Firestore.firestore()
    private var listenerRegistration: ListenerRegistration?

    // MARK: - Lifecycle

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Data Loading

    func loadAudits() {
        isLoading = true
        errorMessage = nil

        let query = db.collection("audits")
            .order(by: "createdAt", descending: true)

        listenerRegistration = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }
            self.handleSnapshot(snapshot, error: error)
        }
    }

    private func handleSnapshot(_ snapshot: QuerySnapshot?, error: Error?) {
        if let error {
            errorMessage = error.localizedDescription
            isLoading = false
            return
        }

        guard let documents = snapshot?.documents else {
            audits = []
            filteredAudits = []
            isLoading = false
            return
        }

        audits = decodeAudits(from: documents)
        filteredAudits = audits
        isLoading = false
    }

    private func decodeAudits(from documents: [QueryDocumentSnapshot]) -> [Audit] {
        documents.compactMap { document in
            do {
                return try document.data(as: Audit.self)
            } catch {
                print("Error decoding audit \(document.documentID): \(error)")
                return nil
            }
        }
    }

    // MARK: - Filtering

    func applyFilters(
        dateFilter: AuditListView.DateFilter,
        userFilter: String,
        roomFilter: String,
        searchText: String
    ) {
        var filtered = audits

        filtered = applyDateFilter(dateFilter, to: filtered)
        filtered = applyUserFilter(userFilter, to: filtered)
        filtered = applyRoomFilter(roomFilter, to: filtered)
        filtered = applySearchFilter(searchText, to: filtered)

        filteredAudits = filtered
    }

    private func applyDateFilter(_ filter: AuditListView.DateFilter, to audits: [Audit]) -> [Audit] {
        let calendar = Calendar.current
        let now = Date()

        switch filter {
        case .today:
            return audits.filter { calendar.isDate($0.auditDate, inSameDayAs: now) }
        case .week:
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            return audits.filter { $0.auditDate >= weekAgo }
        case .month:
            let monthAgo = calendar.date(byAdding: .day, value: -30, to: now) ?? now
            return audits.filter { $0.auditDate >= monthAgo }
        case .all:
            return audits
        }
    }

    private func applyUserFilter(_ filter: String, to audits: [Audit]) -> [Audit] {
        guard !filter.isEmpty else { return audits }
        return audits.filter { $0.auditorName == filter }
    }

    private func applyRoomFilter(_ filter: String, to audits: [Audit]) -> [Audit] {
        guard !filter.isEmpty else { return audits }
        return audits.filter { $0.roomName.localizedCaseInsensitiveContains(filter) }
    }

    private func applySearchFilter(_ searchText: String, to audits: [Audit]) -> [Audit] {
        guard !searchText.isEmpty else { return audits }

        return audits.filter { audit in
            let searchableFields = [
                audit.auditorName,
                audit.cleaningRunId,
                audit.id,
                audit.roomName
            ]
            return searchableFields.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // MARK: - Export

    func exportAudits(format: ExportOptionsView.ExportFormat) {
        switch format {
        case .csv:
            exportAsCSV()
        case .pdf:
            exportAsPDF()
        }
    }

    private func exportAsCSV() {
        let csvString = generateCSVString()
        // TODO: Save to file or share
        print("CSV Export:\n\(csvString)")
    }

    private func exportAsPDF() {
        // TODO: PDF export implementation
        print("PDF export not yet implemented")
    }

    private func generateCSVString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short

        let header = "ID,Auditor,Room,Cleaning Run ID,Score,Status,Audit Date,Created At,Findings,Recommendations\n"

        let rows = filteredAudits.map { audit -> String in
            let escapedAuditor = escapeCSVField(audit.auditorName)
            let escapedRoom = escapeCSVField(audit.roomName)
            let escapedFindings = escapeCSVField(audit.findings.joined(separator: "; "))
            let escapedRecommendations = escapeCSVField(audit.recommendations.joined(separator: "; "))

            return [
                audit.id,
                escapedAuditor,
                escapedRoom,
                audit.cleaningRunId,
                String(audit.score),
                audit.status.rawValue,
                dateFormatter.string(from: audit.auditDate),
                dateFormatter.string(from: audit.createdAt),
                escapedFindings,
                escapedRecommendations
            ].joined(separator: ",")
        }

        return header + rows.joined(separator: "\n")
    }

    private func escapeCSVField(_ field: String) -> String {
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

// MARK: - Mock Data Extension

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
            createdAt: Date().addingTimeInterval(-3600),
            roomName: "Operating Room 1",
            exceptions: []
        )
    }

    static var mockWithExceptions: Audit {
        Audit(
            id: "audit-2",
            cleaningRunId: "run-2",
            auditorName: "Mike Chen",
            auditDate: Date().addingTimeInterval(-7200),
            score: 78.0,
            status: .completed,
            findings: ["Minor issues found", "Documentation incomplete"],
            recommendations: ["Re-train staff on protocol", "Update checklist"],
            createdAt: Date().addingTimeInterval(-7200),
            roomName: "ICU Room B",
            exceptions: ["Missed corner cleaning", "Incomplete PPE disposal"]
        )
    }
}
