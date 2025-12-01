import SwiftUI

struct PersonnelView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedRole: User.UserRole?
    @State private var showingUserDetail = false
    @State private var selectedUser: User?
    
    // Data source - can be injected for testing
    private let dataSource: UserDataSource = MockUserDataSource()
    
    var filteredUsers: [User] {
        dataSource.users.filter { user in
            let matchesSearch = searchText.isEmpty || 
                user.name.localizedCaseInsensitiveContains(searchText) ||
                user.email.localizedCaseInsensitiveContains(searchText) ||
                user.department.localizedCaseInsensitiveContains(searchText)
            
            let matchesRole = selectedRole == nil || user.role == selectedRole
            
            return matchesSearch && matchesRole
        }
    }
    
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
                        
                        // Search and Filter
                        searchFilterSection
                        
                        // Personnel Stats
                        personnelStatsSection
                        
                        // Personnel List
                        personnelListSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Personnel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Add new personnel
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(.accentText)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingUserDetail) {
            if let user = selectedUser {
                UserDetailView(user: user)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Personnel Management")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            
            Text("Manage hospital cleaning staff and their roles")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Search and Filter Section
    private var searchFilterSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondaryText)
                
                TextField("Search personnel...", text: $searchText)
                    .foregroundColor(.primaryText)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondaryText)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
            )
            
            // Role Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All Roles",
                        isSelected: selectedRole == nil
                    ) {
                        selectedRole = nil
                    }
                    
                    ForEach(User.UserRole.allCases, id: \.self) { role in
                        FilterChip(
                            title: role.rawValue.capitalized,
                            isSelected: selectedRole == role
                        ) {
                            selectedRole = role
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Personnel Stats Section
    private var personnelStatsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            PersonnelStatCard(
                title: "Total Staff",
                value: "\(dataSource.users.count)",
                icon: "person.3",
                color: .neonAqua
            )
            
            PersonnelStatCard(
                title: "Active",
                value: "\(dataSource.users.filter { $0.isActive }.count)",
                icon: "person.crop.circle.badge.checkmark",
                color: .successGreen
            )
            
            PersonnelStatCard(
                title: "Inactive",
                value: "\(dataSource.users.filter { !$0.isActive }.count)",
                icon: "person.crop.circle.badge.xmark",
                color: .red
            )
            
            PersonnelStatCard(
                title: "New This Month",
                value: "3",
                icon: "person.badge.plus",
                color: .bluePurpleStart
            )
        }
    }
    
    // MARK: - Personnel List Section
    private var personnelListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Personnel List")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                Spacer()
                
                Text("\(filteredUsers.count) staff")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            if filteredUsers.isEmpty {
                EmptyPersonnelView()
            } else {
                VStack(spacing: 12) {
                    ForEach(filteredUsers) { user in
                        PersonnelRow(user: user) {
                            selectedUser = user
                            showingUserDetail = true
                        }
                    }
                }
            }
        }
    }
    
// MARK: - Supporting Views
struct PersonnelStatCard: View {
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.neonAqua : Color.glassBackground
                )
                .foregroundColor(
                    isSelected ? Color.deepNavy : Color.primaryText
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            isSelected ? Color.clear : Color.glassBorder,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PersonnelRow: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(user.isActive ? Color.neonAqua.opacity(0.2) : Color.secondaryText.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Text(String(user.name.prefix(2)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(user.isActive ? .neonAqua : .secondaryText)
                }
                
                // User Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primaryText)
                        
                        if !user.isActive {
                            Text("Inactive")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.errorRed.opacity(0.2))
                                .foregroundColor(.errorRed)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                    
                    HStack {
                        Text(user.department)
                            .font(.caption2)
                            .foregroundColor(.accentText)
                        
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondaryText)
                        
                        Text(user.role.rawValue.capitalized)
                            .font(.caption2)
                            .foregroundColor(roleColor)
                    }
                }
                
                Spacer()
                
                // Status Indicator
                VStack(spacing: 4) {
                    Circle()
                        .fill(user.isActive ? Color.successGreen : Color.errorRed)
                        .frame(width: 8, height: 8)
                    
                    Text(formatLastLogin(user.lastLogin))
                        .font(.caption2)
                        .foregroundColor(.secondaryText)
                }
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var roleColor: Color {
        switch user.role {
        case .admin: return .errorRed
        case .supervisor: return .warningYellow
        case .auditor: return .neonAqua
        case .cleaner: return .successGreen
        }
    }
    
    private func formatLastLogin(_ date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 3600 {
            return "Active"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

struct EmptyPersonnelView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)
            
            Text("No Personnel Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

#Preview {
    PersonnelView()
        .environmentObject(AppState())
}
