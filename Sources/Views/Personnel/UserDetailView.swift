import SwiftUI

struct UserDetailView: View {
    let user: User
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
                        // Profile Header
                        profileHeaderSection
                        
                        // User Information
                        userInfoSection
                        
                        // Role and Department
                        roleDepartmentSection
                        
                        // Activity Stats
                        activityStatsSection
                        
                        // Recent Activity
                        recentActivitySection
                        
                        // Actions
                        actionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("User Details")
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
    
    // MARK: - Profile Header Section
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(user.isActive ? Color.neonAqua.opacity(0.2) : Color.secondaryText.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(String(user.name.prefix(2)).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(user.isActive ? .neonAqua : .secondaryText)
            }
            
            // Name and Status
            VStack(spacing: 8) {
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(user.isActive ? Color.successGreen : Color.errorRed)
                        .frame(width: 8, height: 8)
                    
                    Text(user.isActive ? "Active" : "Inactive")
                        .font(.subheadline)
                        .foregroundColor(user.isActive ? .successGreen : .errorRed)
                }
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                UserInfoRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: user.email
                )
                
                UserInfoRow(
                    icon: "person.fill",
                    title: "User ID",
                    value: String(user.id.suffix(8))
                )
                
                UserInfoRow(
                    icon: "calendar.fill",
                    title: "Joined",
                    value: formatDate(user.createdAt)
                )
                
                UserInfoRow(
                    icon: "clock.fill",
                    title: "Last Login",
                    value: formatDate(user.lastLogin)
                )
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Role and Department Section
    private var roleDepartmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Role Information")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 16) {
                // Role
                HStack {
                    Image(systemName: "badge.fill")
                        .font(.title3)
                        .foregroundColor(roleColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Role")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Text(user.role.rawValue.capitalized)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(roleColor)
                    }
                    
                    Spacer()
                }
                
                // Department
                HStack {
                    Image(systemName: "building.2.fill")
                        .font(.title3)
                        .foregroundColor(.neonAqua)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Department")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Text(user.department)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Activity Stats Section
    private var activityStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Statistics")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ActivityStatCard(
                    title: "Cycles Today",
                    value: "8",
                    icon: "checkmark.circle.fill",
                    color: .successGreen
                )
                
                ActivityStatCard(
                    title: "Avg. Time",
                    value: "45m",
                    icon: "clock.fill",
                    color: .neonAqua
                )
                
                ActivityStatCard(
                    title: "Compliance",
                    value: "96%",
                    icon: "shield.fill",
                    color: .successGreen
                )
                
                ActivityStatCard(
                    title: "This Month",
                    value: "142",
                    icon: "calendar.badge.plus",
                    color: .bluePurpleStart
                )
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                ForEach(mockRecentActivity.prefix(3)) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if user.isActive {
                Button(action: {
                    // Edit user
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle")
                            .font(.title2)
                        
                        Text("Edit Profile")
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
                
                Button(action: {
                    // Send message
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                            .font(.title2)
                        
                        Text("Send Message")
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
            } else {
                Button(action: {
                    // Reactivate user
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.title2)
                        
                        Text("Reactivate User")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.successGreen, .successGreen.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .successGreen.opacity(0.3), radius: 8)
                }
            }
            
            Button(action: {
                dismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.left.circle")
                        .font(.title2)
                    
                    Text("Back to Personnel")
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
    private var roleColor: Color {
        switch user.role {
        case .admin: return .errorRed
        case .supervisor: return .warningYellow
        case .auditor: return .neonAqua
        case .cleaner: return .successGreen
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Mock data
    private let mockRecentActivity = [
        UserActivity(
            id: "activity-1",
            type: .cleaningCompleted,
            description: "Completed OR Suite Protocol A",
            timestamp: Date().addingTimeInterval(-3600),
            areaName: "Operating Room 1"
        ),
        UserActivity(
            id: "activity-2",
            type: .protocolStarted,
            description: "Started ICU Protocol B",
            timestamp: Date().addingTimeInterval(-7200),
            areaName: "ICU Room A"
        ),
        UserActivity(
            id: "activity-3",
            type: .auditPassed,
            description: "Passed audit with 98% score",
            timestamp: Date().addingTimeInterval(-86400),
            areaName: "Emergency Bay 1"
        )
    ]
}

// MARK: - Supporting Views
struct UserInfoRow: View {
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

struct ActivityStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard()
    }
}

struct ActivityRow: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.description)
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                HStack {
                    Text(activity.areaName)
                        .font(.caption)
                        .foregroundColor(.accentText)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    Text(formatTime(activity.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// NOTE: UserActivity is now defined in Sources/Models/UserActivity.swift
// This avoids duplicate definitions and allows sharing across views

#Preview {
    UserDetailView(user: User.mock)
}
