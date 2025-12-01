import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header Section
                    headerSection
                    
                    // Stats Cards
                    statsSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Quick Actions
                    quickActionsSection
                    
                    // Audit Countdown
                    auditCountdownSection
                }
                .padding()
            }
            .background(Color.deepNavy)
            .navigationTitle("Clean-Flow Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { appState.refreshDashboardData() }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        Button(action: { authService.signOut() }) {
                            Label("Sign Out", systemImage: "arrow.right.square")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.neonAqua)
                            .font(.title2)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back,")
                .font(.title3)
                .foregroundColor(.secondaryText)
            
            Text(authService.currentUser?.name ?? "User")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
                .shadow(color: .neonAqua.opacity(0.5), radius: 2)
            
            Text("\(authService.currentUser?.department ?? "Department") • \(authService.currentUser?.role.rawValue.capitalized ?? "Staff")")
                .font(.subheadline)
                .foregroundColor(.accentText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Today's Cycles",
                value: "\(appState.dashboardStats?.todayRuns ?? 0)",
                subtitle: "Completed: \(appState.dashboardStats?.completedRuns ?? 0)",
                icon: "checkmark.circle.fill",
                color: .successGreen,
                trend: nil
            )
            
            StatCard(
                title: "Compliance Rate",
                value: String(format: "%.1f%%", appState.dashboardStats?.complianceRate ?? 0),
                subtitle: (appState.dashboardStats?.complianceRate ?? 0) >= 95 ? "Above target" : "Below target",
                icon: "shield.checkerboard",
                color: .neonAqua,
                trend: .up
            )
            
            StatCard(
                title: "Avg. Time",
                value: formatDuration(appState.dashboardStats?.averageTime ?? 0),
                subtitle: "Per cycle",
                icon: "clock.fill",
                color: .warningYellow,
                trend: nil
            )
            
            StatCard(
                title: "Next Audit",
                value: formatAuditCountdown(appState.dashboardStats?.nextAuditIn ?? 0),
                subtitle: "Days remaining",
                icon: "calendar.badge.clock",
                color: .bluePurpleStart,
                trend: nil
            )
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            if appState.recentRuns.isEmpty {
                Text("No recent cleaning cycles")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard()
            } else {
                ForEach(appState.recentRuns.prefix(3)) { run in
                    CleaningRunRow(run: run)
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Start Cleaning",
                    icon: "play.circle.fill",
                    color: .neonAqua,
                    action: {
                        appState.selectedTab = .protocols
                    }
                )
                
                QuickActionButton(
                    title: "Scan QR/NFC",
                    icon: "qrcode.viewfinder",
                    color: .successGreen,
                    action: {
                        appState.selectedTab = .scanner
                    }
                )
                
                QuickActionButton(
                    title: "View Audits",
                    icon: "doc.text.magnifyingglass",
                    color: .bluePurpleStart,
                    action: {
                        appState.selectedTab = .audits
                    }
                )
            }
        }
    }
    
    // MARK: - Audit Countdown Section
    private var auditCountdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audit Status")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Audit In")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                    
                    Text(formatAuditCountdown(appState.dashboardStats?.nextAuditIn ?? 0))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentText)
                }
                
                Spacer()
                
                Image(systemName: "shield.checkered")
                    .font(.largeTitle)
                    .foregroundColor(.neonAqua.opacity(0.6))
            }
            .padding()
            .glassCard()
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatAuditCountdown(_ timeInterval: TimeInterval) -> String {
        let days = Int(timeInterval) / 86400
        return "\(days) days"
    }
}

// MARK: - Supporting Views
struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    enum TrendDirection {
        case up, down, stable
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trendIcon(for: trend))
                        .font(.caption)
                        .foregroundColor(trendColor(for: trend))
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.accentText)
                .padding(.top, 4)
        }
        .padding()
        .glassCard()
    }
    
    private func trendIcon(for trend: TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .stable: return "arrow.right"
        }
    }
    
    private func trendColor(for trend: TrendDirection) -> Color {
        switch trend {
        case .up: return .successGreen
        case .down: return .errorRed
        case .stable: return .secondaryText
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CleaningRunRow: View {
    let run: CleaningRun
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(run.areaName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(run.protocolName)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text(formatTime(run.startTime))
                    .font(.caption2)
                    .foregroundColor(.accentText)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                statusBadge(for: run.status)
                
                if let score = run.complianceScore {
                    Text("\(Int(score))%")
                        .font(.caption)
                        .foregroundColor(score >= 90 ? .successGreen : .warningYellow)
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    private func statusBadge(for status: CleaningRun.CleaningStatus) -> some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor(for: status).opacity(0.2))
            .foregroundColor(statusColor(for: status))
            .clipShape(Capsule())
    }
    
    private func statusColor(for status: CleaningRun.CleaningStatus) -> Color {
        switch status {
        case .completed, .verified: return .successGreen
        case .inProgress: return .neonAqua
        case .failed: return .errorRed
        case .pending: return .secondaryText
        case .audited: return .bluePurpleStart
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
