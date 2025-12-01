import SwiftUI

struct StaffListView: View {
    @StateObject private var viewModel = StaffListViewModel()
    @State private var selectedStaff: User?
    @State private var showingStaffDetail = false
    @State private var showingAddStaff = false
    @State private var selectedRole: User.UserRole?
    @State private var searchText = ""
    
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
                
                VStack(spacing: 0) {
                    // Stats Overview
                    statsOverview
                    
                    // Search and Filters
                    searchAndFilters
                    
                    // Staff List
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredStaff.isEmpty {
                        emptyStateView
                    } else {
                        staffList
                    }
                }
            }
            .navigationTitle("Personnel")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddStaff = true
                    }) {
                        Image(systemName: "person.badge.plus")
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingStaffDetail) {
            if let staff = selectedStaff {
                StaffDetailView(user: staff)
            }
        }
        .sheet(isPresented: $showingAddStaff) {
            AddStaffView()
        }
        .onAppear {
            viewModel.loadStaff()
        }
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80, maximum: .infinity))
        ], spacing: 16) {
            StaffStatCard(
                title: "Total Staff",
                value: "\(viewModel.totalStaff)",
                icon: "person.3.fill",
                color: Color(red: 43/255, green: 203/255, blue: 255/255)
            )
            
            StaffStatCard(
                title: "Active Today",
                value: "\(viewModel.activeToday)",
                icon: "checkmark.circle.fill",
                color: Color(red: 100/255, green: 255/255, blue: 100/255)
            )
            
            StaffStatCard(
                title: "On Leave",
                value: "\(viewModel.onLeave)",
                icon: "calendar.badge.minus",
                color: Color(red: 255/255, green: 200/255, blue: 100/255)
            )
            
            StaffStatCard(
                title: "New This Month",
                value: "\(viewModel.newThisMonth)",
                icon: "person.badge.plus",
                color: Color(red: 138/255, green: 77/255, blue: 255/255)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }
    
    // MARK: - Search and Filters
    private var searchAndFilters: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Color.white.opacity(0.6))
                
                TextField("Search personnel...", text: $searchText)
                    .foregroundColor(.white)
                    .onChange(of: searchText) { newValue in
                        viewModel.applyFilters(role: selectedRole, searchText: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            
            // Role Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    RoleFilterChip(
                        title: "All Roles",
                        isSelected: selectedRole == nil
                    ) {
                        selectedRole = nil
                        viewModel.applyFilters(role: selectedRole, searchText: searchText)
                    }
                    
                    ForEach(User.UserRole.allCases, id: \.self) { role in
                        RoleFilterChip(
                            title: role.rawValue.capitalized,
                            isSelected: selectedRole == role
                        ) {
                            selectedRole = role
                            viewModel.applyFilters(role: selectedRole, searchText: searchText)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Staff List
    private var staffList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredStaff) { staff in
                    StaffCard(user: staff) {
                        selectedStaff = staff
                        showingStaffDetail = true
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 43/255, green: 203/255, blue: 255/255)))
                .scaleEffect(1.5)
            
            Text("Loading staff...")
                .foregroundColor(Color.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(Color.white.opacity(0.4))
            
            Text("No Staff Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}

// MARK: - Staff Stat Card
struct StaffStatCard: View {
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

// MARK: - Role Filter Chip
struct RoleFilterChip: View {
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
                    isSelected ? Color(red: 43/255, green: 203/255, blue: 255/255) : Color.white.opacity(0.1)
                )
                .foregroundColor(
                    isSelected ? Color(red: 6/255, green: 10/255, blue: 25/255) : .white
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? Color.clear : Color.white.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Staff Card
struct StaffCard: View {
    let user: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(user.isActive ? Color(red: 43/255, green: 203/255, blue: 255/255).opacity(0.2) : Color.white.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text(String(user.name.prefix(2)).uppercased())
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(user.isActive ? Color(red: 43/255, green: 203/255, blue: 255/255) : Color.white.opacity(0.6))
                }
                
                // Staff Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(user.name)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if !user.isActive {
                            Text("Inactive")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 255/255, green: 100/255, blue: 100/255).opacity(0.2))
                                .foregroundColor(Color(red: 255/255, green: 100/255, blue: 100/255))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(user.email)
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    HStack {
                        Text(user.department)
                            .font(.caption)
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(Color.white.opacity(0.4))
                        
                        Text(user.role.rawValue.capitalized)
                            .font(.caption)
                            .foregroundColor(roleColor)
                    }
                }
                
                Spacer()
                
                // Status and Activity
                VStack(alignment: .trailing, spacing: 4) {
                    Circle()
                        .fill(user.isActive ? Color(red: 100/255, green: 255/255, blue: 100/255) : Color(red: 255/255, green: 100/255, blue: 100/255))
                        .frame(width: 8, height: 8)
                    
                    Text(formatLastLogin(user.lastLogin))
                        .font(.caption2)
                        .foregroundColor(Color.white.opacity(0.6))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var roleColor: Color {
        switch user.role {
        case .admin: return Color(red: 255/255, green: 100/255, blue: 100/255)
        case .supervisor: return Color(red: 255/255, green: 200/255, blue: 100/255)
        case .auditor: return Color(red: 43/255, green: 203/255, blue: 255/255)
        case .cleaner: return Color(red: 100/255, green: 255/255, blue: 100/255)
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

#Preview {
    StaffListView()
}
