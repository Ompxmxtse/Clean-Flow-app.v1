// MARK: - Enhanced Navigation System
import SwiftUI

// MARK: - Enhanced Root View
struct EnhancedRootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if !authService.isAuthenticated {
                LoginView()
            } else {
                MainNavigationView()
                    .environmentObject(appState)
                    .environmentObject(authService)
            }
        }
    }
}

// MARK: - Main Navigation with Sidebar
struct MainNavigationView: View {
    @State private var showingSidebar = false
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Main content
            TabView(selection: $selectedTab) {
                EnhancedDashboardView()
                    .environmentObject(appState)
                    .tag(0)
                
                ProtocolsView()
                    .tag(1)
                
                ScannerView()
                    .tag(2)
                
                AuditsView()
                    .tag(3)
                
                PersonnelView()
                    .tag(4)
            }
            
            // Sidebar overlay
            if showingSidebar {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            showingSidebar = false
                        }
                    }
                
                SidebarView(isShowing: $showingSidebar, selectedTab: $selectedTab)
                    .transition(.move(edge: .leading))
            }
        }
        .overlay(alignment: .topLeading) {
            if !showingSidebar {
                Button {
                    withAnimation(.spring()) {
                        showingSidebar = true
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(CleanFlowTheme.card)
                        .clipShape(Circle())
                        .shadow(color: CleanFlowTheme.neonCyan.opacity(0.3), radius: 8)
                }
                .padding()
            }
        }
    }
}

// MARK: - Sidebar Navigation
struct SidebarView: View {
    @Binding var isShowing: Bool
    @Binding var selectedTab: Int
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header with logo
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        NeonCLogoView()
                            .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Clean-Flow")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            Text("v1.0.0")
                                .font(.caption2)
                                .foregroundColor(CleanFlowTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring()) {
                                isShowing = false
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding(8)
                        }
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                }
                .padding()
                .background(CleanFlowTheme.card)
                
                // Navigation items
                ScrollView {
                    VStack(spacing: 4) {
                        SidebarItem(icon: "speedometer", title: "Dashboard", isSelected: selectedTab == 0) {
                            selectedTab = 0
                            isShowing = false
                        }
                        
                        SidebarItem(icon: "doc.text", title: "Protocols", isSelected: selectedTab == 1) {
                            selectedTab = 1
                            isShowing = false
                        }
                        
                        SidebarItem(icon: "qrcode.viewfinder", title: "Scan", isSelected: selectedTab == 2) {
                            selectedTab = 2
                            isShowing = false
                        }
                        
                        SidebarItem(icon: "clock.arrow.circlepath", title: "Audit Logs", isSelected: selectedTab == 3) {
                            selectedTab = 3
                            isShowing = false
                        }
                        
                        SidebarItem(icon: "person.crop.circle", title: "Personnel", isSelected: selectedTab == 4) {
                            selectedTab = 4
                            isShowing = false
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.2))
                            .padding(.vertical, 8)
                        
                        SidebarItem(icon: "gearshape", title: "Settings", isSelected: false) {
                            // Navigate to settings
                            selectedTab = 5
                            isShowing = false
                        }
                        
                        SidebarItem(icon: "questionmark.circle", title: "Help & Support", isSelected: false) {
                            // Navigate to help
                            isShowing = false
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Spacer()
                
                // User info
                VStack(spacing: 8) {
                    HStack {
                        Circle()
                            .fill(CleanFlowTheme.neonCyan.opacity(0.2))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(appState.currentUser?.name.prefix(1) ?? "U"))
                                    .font(.headline)
                                    .foregroundColor(CleanFlowTheme.neonCyan)
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appState.currentUser?.name ?? "User")
                                .font(.subheadline)
                                .foregroundColor(.white)
                            
                            Text(appState.currentUser?.role.rawValue.capitalized ?? "Staff")
                                .font(.caption)
                                .foregroundColor(CleanFlowTheme.textSecondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    
                    // Sign out button
                    Button {
                        try? authService.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding()
                }
            }
            .frame(width: 280)
            .background(CleanFlowTheme.background)
            .shadow(color: .black.opacity(0.3), radius: 20)
            
            Spacer()
        }
    }
}

// MARK: - Sidebar Item Component
struct SidebarItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? CleanFlowTheme.neonCyan : .white.opacity(0.7))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(CleanFlowTheme.neonCyan)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected ?
                    LinearGradient(
                        colors: [CleanFlowTheme.neonCyan.opacity(0.2), CleanFlowTheme.neonBlue.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
            )
            .cornerRadius(12)
            .padding(.horizontal, 8)
        }
    }
}
