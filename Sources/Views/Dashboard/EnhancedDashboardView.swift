// MARK: - Enhanced Dashboard Components
import SwiftUI

// MARK: - Stat Card Component
struct StatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(CleanFlowTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(CleanFlowTheme.card)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(iconColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Telemetry Item Component
struct TelemetryItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(CleanFlowTheme.textSecondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.system(size: 11))
                .foregroundColor(CleanFlowTheme.textSecondary)
        }
        .padding()
        .background(CleanFlowTheme.card)
        .cornerRadius(12)
    }
}

// MARK: - Enhanced Dashboard View
struct EnhancedDashboardView: View {
    @State private var complianceRate = 92
    @State private var pendingTasks = 14
    @State private var activeUnits = "10/12"
    @State private var showingDetails = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            CleanFlowTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Good morning,")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(.white)
                            Text(appState.currentUser?.name ?? "Dr. Admin")
                                .font(.system(size: 16, weight: .light))
                                .foregroundColor(CleanFlowTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            // Notifications
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(CleanFlowTheme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 60)
                    
                    // Compliance Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Compliance Rate")
                                    .font(.caption)
                                    .foregroundColor(CleanFlowTheme.textSecondary)
                                
                                Text("\(complianceRate)%")
                                    .font(.system(size: 36, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 10))
                                    Text("+4.5% this week")
                                        .font(.caption2)
                                }
                                .foregroundColor(CleanFlowTheme.successGreen)
                            }
                            
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill(CleanFlowTheme.neonCyan.opacity(0.2))
                                    .frame(width: 64, height: 64)
                                
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 28))
                                    .foregroundColor(CleanFlowTheme.neonCyan)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button("Track") {
                                //
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            Button("Report") {
                                //
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [
                                CleanFlowTheme.neonCyan.opacity(0.2),
                                CleanFlowTheme.neonBlue.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(24)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(CleanFlowTheme.neonCyan.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: CleanFlowTheme.neonCyan.opacity(0.2), radius: 20)
                    .padding(.horizontal)
                    
                    // Quick Stats
                    HStack(spacing: 12) {
                        StatCard(
                            icon: "exclamationmark.triangle",
                            iconColor: CleanFlowTheme.warningYellow,
                            value: "\(pendingTasks)",
                            label: "Pending Tasks"
                        )
                        
                        StatCard(
                            icon: "person.3.fill",
                            iconColor: CleanFlowTheme.successGreen,
                            value: activeUnits,
                            label: "Active Units"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Live Telemetry
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Live Telemetry")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button("View all") {
                                //
                            }
                            .font(.caption)
                            .foregroundColor(CleanFlowTheme.neonCyan)
                        }
                        
                        VStack(spacing: 12) {
                            TelemetryItem(
                                icon: "checkmark.circle.fill",
                                iconColor: CleanFlowTheme.successGreen,
                                title: "Room 304 Sanitized",
                                subtitle: "Verified by Mark T.",
                                time: "2m ago"
                            )
                            
                            TelemetryItem(
                                icon: "exclamationmark.circle.fill",
                                iconColor: CleanFlowTheme.warningYellow,
                                title: "Hazard: Lobby",
                                subtitle: "Unit dispatched",
                                time: "15m ago"
                            )
                            
                            TelemetryItem(
                                icon: "person.fill.checkmark",
                                iconColor: Color(red: 59/255, green: 130/255, blue: 246/255),
                                title: "Shift Started",
                                subtitle: "Maria G. check-in",
                                time: "1h ago"
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Attention Required
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Attention Required")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("OR - Surgical Suite 2")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("OVERDUE")
                                .font(.caption2.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(6)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
    }
}
