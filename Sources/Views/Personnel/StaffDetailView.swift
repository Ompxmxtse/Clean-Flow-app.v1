import SwiftUI

struct StaffDetailView: View {
    let user: User
struct StaffDetailView: View {
    let user: User
    @StateObject private var viewModel: StaffDetailViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    @State private var showingActivityHistory = false
    
    init(user: User) {
        self.user = user
        _viewModel = StateObject(wrappedValue: StaffDetailViewModel(user: user))
    }
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    @State private var showingActivityHistory = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 6/255, green: 10/255, blue: 25/255),
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Header
                        profileHeader
                        
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
            .navigationTitle("Staff Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingEditProfile) {
            EditStaffView(user: user)
        }
        .sheet(isPresented: $showingActivityHistory) {
            ActivityHistoryView(user: user)
        }
        .onAppear {
            viewModel.loadActivityData()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(user.isActive ? Color(red: 43/255, green: 203/255, blue: 255/255).opacity(0.2) : Color.white.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Text(String(user.name.prefix(2)).uppercased())
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(user.isActive ? Color(red: 43/255, green: 203/255, blue: 255/255) : Color.white.opacity(0.6))
            }
            
            // Name and Status
            VStack(spacing: 8) {
                Text(user.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(user.isActive ? Color(red: 100/255, green: 255/255, blue: 100/255) : Color(red: 255/255, green: 100/255, blue: 100/255))
                        .frame(width: 8, height: 8)
                    
                    Text(user.isActive ? "Active" : "Inactive")
                        .font(.subheadline)
                        .foregroundColor(user.isActive ? Color(red: 100/255, green: 255/255, blue: 100/255) : Color(red: 255/255, green: 100/255, blue: 100/255))
                }
            }
        }
        .padding(.top, 40)
    }
    
    // MARK: - User Info Section
    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Contact Information")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                UserInfoRow(
                    icon: "envelope.fill",
                    title: "Email",
                    value: user.email
                )
                
                UserInfoRow(
                    icon: "person.fill",
                    title: "User ID",
                    value: user.id.suffix(8)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Role and Department Section
    private var roleDepartmentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Role Information")
                .font(.headline)
                .foregroundColor(.white)
            
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
                            .foregroundColor(Color.white.opacity(0.6))
                        
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
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Department")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.6))
                        
                        Text(user.department)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Activity Stats Section
    private var activityStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ActivityStatCard(
                    title: "Cycles Today",
                    value: "\(viewModel.cyclesToday)",
                    icon: "checkmark.circle.fill",
                    color: Color(red: 100/255, green: 255/255, blue: 100/255)
                )
                
                ActivityStatCard(
                    title: "Avg. Time",
                    value: "\(viewModel.averageTime) min",
                    icon: "clock.fill",
                    color: Color(red: 43/255, green: 203/255, blue: 255/255)
                )
                
                ActivityStatCard(
                    title: "Compliance",
                    value: "\(viewModel.complianceRate)%",
                    icon: "shield.fill",
                    color: Color(red: 100/255, green: 255/255, blue: 100/255)
                )
                
                ActivityStatCard(
                    title: "This Month",
                    value: "\(viewModel.monthlyCycles)",
                    icon: "calendar.badge.plus",
                    color: Color(red: 138/255, green: 77/255, blue: 255/255)
                )
            }
        }
    }
    
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingActivityHistory = true
                }
                .font(.caption)
                .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
            }
            
            VStack(spacing: 12) {
                ForEach(viewModel.recentActivity.prefix(3)) { activity in
                    ActivityRow(activity: activity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if user.isActive {
                Button(action: {
                    showingEditProfile = true
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
                            gradient: Gradient(colors: [
                                Color(red: 43/255, green: 203/255, blue: 255/255),
                                Color(red: 138/255, green: 77/255, blue: 255/255)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(red: 43/255, green: 203/255, blue: 255/255).opacity(0.3), radius: 10)
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
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(16)
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
                            gradient: Gradient(colors: [
                                Color(red: 100/255, green: 255/255, blue: 100/255),
                                Color(red: 100/255, green: 255/255, blue: 100/255).opacity(0.8)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(red: 100/255, green: 255/255, blue: 100/255).opacity(0.3), radius: 10)
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
                .background(Color.white.opacity(0.1))
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Helper Properties
    private var roleColor: Color {
        switch user.role {
        case .admin: return Color(red: 255/255, green: 100/255, blue: 100/255)
        case .supervisor: return Color(red: 255/255, green: 200/255, blue: 100/255)
        case .auditor: return Color(red: 43/255, green: 203/255, blue: 255/255)
        case .cleaner: return Color(red: 100/255, green: 255/255, blue: 100/255)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
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
                .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.white.opacity(0.6))
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
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
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
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
                    .foregroundColor(.white)
                
                HStack {
                    Text(activity.areaName)
                        .font(.caption)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.4))
                    
                    Text(formatTime(activity.timestamp))
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.4))
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

#Preview {
    StaffDetailView(user: User.mock)
}
