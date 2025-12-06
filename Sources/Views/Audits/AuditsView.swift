import SwiftUI

struct AuditsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedAudit: Audit?
    @State private var showingAuditDetail = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.deepNavy,
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    LazyVStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Audit Stats
                        auditStatsSection
                        
                        // Recent Audits
                        recentAuditsSection
                        
                        // Upcoming Audits
                        upcomingAuditsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Audits")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Create new audit
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentText)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAuditDetail) {
            if let audit = selectedAudit {
                AuditDetailView(audit: audit)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit Management")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text("Monitor and review cleaning protocol compliance")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Audit Stats Section
    private var auditStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            AuditStatCard(
                title: "This Month",
                value: "12",
                subtitle: "Audits completed",
                icon: "checkmark.circle.fill",
                color: .successGreen
            )
            
            AuditStatCard(
                title: "Avg Score",
                value: "94.5%",
                subtitle: "Compliance rate",
                icon: "chart.bar.fill",
                color: .neonAqua
            )
            
            AuditStatCard(
                title: "Pending",
                value: "3",
                subtitle: "Awaiting review",
                icon: "clock.fill",
                color: .warningYellow
            )
        }
    }
    
    // MARK: - Recent Audits Section
    private var recentAuditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Audits")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                ForEach(mockRecentAudits.prefix(3)) { audit in
                    AuditRow(audit: audit) {
                        selectedAudit = audit
                        showingAuditDetail = true
                    }
                }
            }
        }
    }
    
    // MARK: - Upcoming Audits Section
    private var upcomingAuditsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Upcoming Audits")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                ForEach(mockUpcomingAudits.prefix(2)) { audit in
                    UpcomingAuditRow(audit: audit)
                }
            }
        }
    }
    
    // Mock Data
    private let mockRecentAudits = [
        Audit(
            id: "audit-1",
            cleaningRunId: "run-1",
            auditorName: "Dr. Sarah Johnson",
            auditDate: Date().addingTimeInterval(-86400),
            score: 95.0,
            status: .completed,
            findings: ["All steps completed correctly", "Excellent documentation"],
            recommendations: ["Maintain current standards"],
            createdAt: Date().addingTimeInterval(-86400)
        ),
        Audit(
            id: "audit-2",
            cleaningRunId: "run-2",
            auditorName: "Mike Chen",
            auditDate: Date().addingTimeInterval(-172800),
            score: 88.0,
            status: .completed,
            findings: ["Minor documentation issues", "One step missed"],
            recommendations: ["Improve checklist completion", "Additional training required"],
            createdAt: Date().addingTimeInterval(-172800)
        ),
        Audit(
            id: "audit-3",
            cleaningRunId: "run-3",
            auditorName: "Lisa Anderson",
            auditDate: Date().addingTimeInterval(-259200),
            score: 92.0,
            status: .inProgress,
            findings: ["Review in progress"],
            recommendations: [],
            createdAt: Date().addingTimeInterval(-259200)
        )
    ]
    
    private let mockUpcomingAudits = [
        UpcomingAudit(
            id: "upcoming-1",
            areaName: "Operating Room 1",
            scheduledDate: Date().addingTimeInterval(86400),
            auditorName: "Dr. Sarah Johnson",
            protocolName: "OR Suite Protocol A"
        ),
        UpcomingAudit(
            id: "upcoming-2",
            areaName: "ICU Room A",
            scheduledDate: Date().addingTimeInterval(172800),
            auditorName: "Mike Chen",
            protocolName: "ICU Protocol B"
        )
    ]
}

// MARK: - Supporting Views
struct AuditStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.accentText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard()
    }
}

struct AuditRow: View {
    let audit: Audit
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Audit #\(audit.id.suffix(4))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                    
                    Text(audit.auditorName)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Text(formatDate(audit.auditDate))
                        .font(.caption2)
                        .foregroundColor(.accentText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    scoreBadge
                    statusBadge
                }
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var scoreBadge: some View {
        Text("\(Int(audit.score))%")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(scoreColor)
    }
    
    private var statusBadge: some View {
        Text(audit.status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var scoreColor: Color {
        if audit.score >= 90 { return .successGreen }
        else if audit.score >= 75 { return .warningYellow }
        else { return .errorRed }
    }
    
    private var statusColor: Color {
        switch audit.status {
        case .completed: return .successGreen
        case .inProgress: return .neonAqua
        case .pending: return .warningYellow
        case .failed: return .errorRed
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}

struct UpcomingAuditRow: View {
    let audit: UpcomingAudit
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(audit.areaName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(audit.protocolName)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text("Auditor: \(audit.auditorName)")
                    .font(.caption2)
                    .foregroundColor(.accentText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDate(audit.scheduledDate))
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(formatTimeRemaining(audit.scheduledDate))
                    .font(.caption2)
                    .foregroundColor(.warningYellow)
            }
        }
        .padding()
        .glassCard()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTimeRemaining(_ date: Date) -> String {
        let days = Int(date.timeIntervalSinceNow) / 86400
        if days == 0 { return "Today" }
        else if days == 1 { return "Tomorrow" }
        else { return "\(days) days" }
    }
}

// MARK: - Data Models

// Top-level AuditStatus for broader access
enum AuditStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"
    case failed = "failed"
}

struct Audit: Identifiable, Codable {
    let id: String
    let cleaningRunId: String
    let auditorName: String
    let auditDate: Date
    let score: Double
    let status: AuditStatus
    let findings: [String]
    let recommendations: [String]
    let createdAt: Date
    let roomName: String
    let exceptions: [String]

    // MARK: - Computed Properties

    var complianceScore: Double { score }
    var hasExceptions: Bool { !exceptions.isEmpty }
    var exceptionCount: Int { exceptions.count }

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case cleaningRunId
        case auditorName
        case auditDate
        case score = "complianceScore"
        case status
        case findings
        case recommendations
        case createdAt
        case roomName
        case exceptions
    }

    // MARK: - Initializers

    init(
        id: String,
        cleaningRunId: String,
        auditorName: String,
        auditDate: Date,
        score: Double,
        status: AuditStatus,
        findings: [String],
        recommendations: [String],
        createdAt: Date,
        roomName: String = "",
        exceptions: [String] = []
    ) {
        self.id = id
        self.cleaningRunId = cleaningRunId
        self.auditorName = auditorName
        self.auditDate = auditDate
        self.score = score
        self.status = status
        self.findings = findings
        self.recommendations = recommendations
        self.createdAt = createdAt
        self.roomName = roomName
        self.exceptions = exceptions
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        cleaningRunId = try container.decodeIfPresent(String.self, forKey: .cleaningRunId) ?? ""
        auditorName = try container.decodeIfPresent(String.self, forKey: .auditorName) ?? ""
        auditDate = try container.decodeIfPresent(Date.self, forKey: .auditDate) ?? Date()
        score = try container.decodeIfPresent(Double.self, forKey: .score) ?? 0.0
        status = try container.decodeIfPresent(AuditStatus.self, forKey: .status) ?? .pending
        findings = try container.decodeIfPresent([String].self, forKey: .findings) ?? []
        recommendations = try container.decodeIfPresent([String].self, forKey: .recommendations) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        roomName = try container.decodeIfPresent(String.self, forKey: .roomName) ?? ""
        exceptions = try container.decodeIfPresent([String].self, forKey: .exceptions) ?? []
    }
}

struct UpcomingAudit: Identifiable {
    let id: String
    let areaName: String
    let scheduledDate: Date
    let auditorName: String
    let protocolName: String
}

#Preview {
    AuditsView()
        .environmentObject(AppState())
}
