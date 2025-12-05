import SwiftUI

struct ProtocolsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProtocolDetail = false
    @State private var selectedProtocol: CleaningProtocol?
    @State private var searchText = ""
    
    var filteredProtocols: [CleaningProtocol] {
        if searchText.isEmpty {
            return appState.protocols
        } else {
            return appState.protocols.filter { cleaningProtocol in
                cleaningProtocol.name.localizedCaseInsensitiveContains(searchText) ||
                cleaningProtocol.description.localizedCaseInsensitiveContains(searchText)
            }
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
                
                if let activeRun = appState.activeCleaningRun {
                    // Active Protocol View
                    ActiveProtocolView(run: activeRun)
                        .transition(.opacity)
                } else {
                    // Protocols List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Search Bar
                            searchBar
                            
                            // Protocols Grid
                            if filteredProtocols.isEmpty {
                                emptyStateView
                            } else {
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 16) {
                                    ForEach(filteredProtocols) { cleaningProtocol in
                                        ProtocolCard(cleaningProtocol: cleaningProtocol) {
                                            selectedProtocol = cleaningProtocol
                                            showingProtocolDetail = true
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Cleaning Protocols")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        appState.refreshDashboardData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentText)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search protocols...")
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingProtocolDetail) {
            if let cleaningProtocol = selectedProtocol {
                ProtocolDetailView(cleaningProtocol: cleaningProtocol)
                    .environmentObject(appState)
            }
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondaryText)
            
            TextField("Search protocols...", text: $searchText)
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
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 60))
                .foregroundColor(.secondaryText)
            
            Text("No Protocols Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Try adjusting your search or check back later")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

// MARK: - Active Protocol View
struct ActiveProtocolView: View {
    let run: CleaningRun
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("Active Cleaning Protocol")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text(run.protocolName)
                        .font(.headline)
                        .foregroundColor(.accentText)
                    
                    Text(run.areaName)
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                .padding(.top, 20)
                
                // Progress
                VStack(spacing: 12) {
                    HStack {
                        Text("Progress")
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Text("\(min(appState.currentStepIndex + 1, run.steps.count)) of \(run.steps.count)")
                            .font(.subheadline)
                            .foregroundColor(.accentText)
                    }
                    
                    ProgressView(value: min(Double(appState.currentStepIndex + 1), Double(run.steps.count)), total: Double(run.steps.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .neonAqua))
                }
                .padding()
                .glassCard()
                
                // Current Step
                if appState.currentStepIndex < run.steps.count {
                    let currentStep = run.steps[appState.currentStepIndex]

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Step")
                            .font(.headline)
                            .foregroundColor(.primaryText)

                        // Display the protocol step with completion status
                        if let protocolStep = getProtocolStep(for: currentStep) {
                            StepDetailView(
                                step: protocolStep,
                                isCompleted: currentStep.completed,
                                note: currentStep.notes,
                                onAction: { _ in }  // No action in this context
                            )
                        } else {
                            // Fallback: show completed step info
                            VStack(alignment: .leading, spacing: 8) {
                                Text(currentStep.name)
                                    .font(.subheadline)
                                    .foregroundColor(.primaryText)
                                if let notes = currentStep.notes {
                                    Text(notes)
                                        .font(.caption)
                                        .foregroundColor(.secondaryText)
                                }
                            }
                        }
                    }
                    .padding()
                    .glassCard()
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        appState.completeCurrentStep()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title2)
                            
                            Text("Complete Step")
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
                    
                    Button(action: {
                        appState.cancelCleaningRun()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle")
                                .font(.title2)
                            
                            Text("Cancel Protocol")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.glassBackground)
                        .foregroundColor(.errorRed)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.errorRed.opacity(0.3), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func getProtocolStep(for completedStep: CompletedStep) -> CleaningStep? {
        // Find the corresponding protocol step
        return appState.protocols.first { $0.id == run.protocolId }?
            .steps.first { $0.id == completedStep.stepId }
    }
}

#Preview {
    ProtocolsView()
        .environmentObject(AppState())
}
