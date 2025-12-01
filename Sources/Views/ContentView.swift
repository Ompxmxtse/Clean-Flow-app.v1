import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        EnhancedRootView()
            .environmentObject(appState)
            .environmentObject(authService)
            .onAppear {
                appState.refreshDashboardData()
            }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(AppState())
}