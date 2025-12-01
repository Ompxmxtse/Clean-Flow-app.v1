import SwiftUI

struct AuditDetailView: View {
    let audit: Audit
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(spacing: 20) {
                        // Header
                        headerSection
                        
                        // Score Overview
                        scoreSection
                        
                        // Findings
                        if !audit.findings.isEmpty {
                            findingsSection
                        }
                        
                        // Recommendations
                        if !audit.recommendations.isEmpty {
                            recommendationsSection
                        }
                        
                        // Audit Details
                        auditDetailsSection
                        
                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Audit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Audit #\(String(audit.id.suffix(4)).padding(toLength: 4, withPad: "0", startingAt: 0))")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text("Audited by \(audit.auditorName)")
                .font(.subheadline)
                .foregroundColor(.accentText)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Score Section
    private var scoreSection: some View {
        VStack(spacing: 16) {
            Text("Compliance Score")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.glassBorder, lineWidth: 8)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: audit.score / 100)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [scoreColor, scoreColor.opacity(0.6)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(Int(audit.score))%")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(scoreColor)
                        
                        Text("Score")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                    }
                }
                .padding()
                
                Text(scoreMessage)
                    .font(.subheadline)
                    .foregroundColor(scoreColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Findings Section
    private var findingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Findings")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                ForEach(audit.findings, id: \.self) { finding in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle.fill")
                            .font(.title3)
                            .foregroundColor(.neonAqua)
                            .frame(width: 24)
                        
                        Text(finding)
                            .font(.subheadline)
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Recommendations Section
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                ForEach(audit.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .font(.title3)
                            .foregroundColor(.warningYellow)
                            .frame(width: 24)
                        
                        Text(recommendation)
                            .font(.subheadline)
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Audit Details Section
    private var auditDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit Information")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                DetailRow(
                    icon: "person.fill",
                    title: "Auditor",
                    value: audit.auditorName
                )
                
                DetailRow(
                    icon: "calendar",
                    title: "Audit Date",
                    value: formatDate(audit.auditDate)
                )
                
                DetailRow(
                    icon: "clock",
                    title: "Status",
                    value: audit.status.rawValue.capitalized
                )
                
                DetailRow(
                    icon: "doc.text",
                    title: "Cleaning Run ID",
                    value: audit.cleaningRunId.suffix(8)
                )
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if audit.status == .completed {
                Button(action: {
                    // Export audit report
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                        
                        Text("Export Report")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.neonAqua, .bluePurpleStart]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .neonAqua.opacity(0.3), radius: 8)
                }
            }
            
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.left.circle")
                        .font(.title2)
                    
                    Text("Back to Audits")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.glassBackground)
                .foregroundColor(.primaryText)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.glassBorder, lineWidth: 1)
                )
                .cornerRadius(12)
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Properties
    private var scoreColor: Color {
        if audit.score >= 90 { return .successGreen }
        else if audit.score >= 75 { return .warningYellow }
        else { return .errorRed }
    }
    
    private var scoreMessage: String {
        if audit.score >= 95 { return "Excellent performance!" }
        else if audit.score >= 90 { return "Very good compliance" }
        else if audit.score >= 80 { return "Good performance" }
        else if audit.score >= 70 { return "Needs improvement" }
        else { return "Requires immediate attention" }
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func formatDate(_ date: Date) -> String {
        return Self.dateFormatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentText)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AuditDetailView(audit: Audit(
        id: "audit-1",
        cleaningRunId: "run-1",
        auditorName: "Dr. Sarah Johnson",
        auditDate: Date().addingTimeInterval(-86400),
        score: 95.0,
        status: .completed,
        findings: ["All steps completed correctly", "Excellent documentation", "No issues found"],
        recommendations: ["Maintain current standards"],
        createdAt: Date().addingTimeInterval(-86400)
    ))
}
