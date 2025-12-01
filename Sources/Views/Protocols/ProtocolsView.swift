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
                                EmptyStateView()
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
    private var EmptyStateView: some View {
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

// MARK: - Protocol Card
struct ProtocolCard: View {
    let cleaningProtocol: CleaningProtocol
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(cleaningProtocol.name)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                            .multilineTextAlignment(.leading)
                        
                        Text(cleaningProtocol.description)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    priorityBadge
                }
                
                // Details
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.accentText)
                        
                        Text("\(formatDuration(cleaningProtocol.requiredDuration))")
                            .font(.caption)
                            .foregroundColor(.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "list.bullet")
                            .font(.caption)
                            .foregroundColor(.accentText)
                        
                        Text("\(cleaningProtocol.steps.count) steps")
                            .font(.caption)
                            .foregroundColor(.primaryText)
                    }
                    
                    HStack {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.accentText)
                        
                        Text(cleaningProtocol.areaType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.primaryText)
                    }
                }
                
                // Progress Bar (mock - deterministic based on protocol ID hash)
                ProgressView(value: Double(abs(cleaningProtocol.id.hashValue % 30) + 60) / 100.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .neonAqua))
                    .scaleEffect(y: 0.8)
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityBadge: some View {
        Text(cleaningProtocol.priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(priorityColor.opacity(0.2))
            .foregroundColor(priorityColor)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch cleaningProtocol.priority {
        case .critical: return .errorRed
        case .high: return .warningYellow
        case .medium: return .neonAqua
        case .low: return .secondaryText
        }
    }
    
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
                        
                        StepDetailView(step: currentStep, protocolStep: getProtocolStep(for: currentStep))
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

// MARK: - Step Detail View
struct StepDetailView: View {
    let step: CompletedStep
    let protocolStep: CleaningStep?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step Name
            Text(step.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            if let protocolStep = protocolStep {
                // Description
                Text(protocolStep.description)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                
                // Equipment
                if !protocolStep.equipment.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required Equipment:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(protocolStep.equipment, id: \.self) { equipment in
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.successGreen)
                                    
                                    Text(equipment)
                                        .font(.caption)
                                        .foregroundColor(.primaryText)
                                }
                            }
                        }
                    }
                }
                
                // Chemicals
                if !protocolStep.chemicals.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required Chemicals:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(protocolStep.chemicals, id: \.self) { chemical in
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .font(.caption)
                                        .foregroundColor(.successGreen)
                                    
                                    Text(chemical)
                                        .font(.caption)
                                        .foregroundColor(.primaryText)
                                }
                            }
                        }
                    }
                }
                
                // Checklist
                if !protocolStep.checklistItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Checklist:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.accentText)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(step.checklistItems) { item in
                                HStack {
                                    Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                                        .font(.caption)
                                        .foregroundColor(item.completed ? .successGreen : .secondaryText)
                                    
                                    Text(item.item)
                                        .font(.caption)
                                        .foregroundColor(.primaryText)
                                        .strikethrough(item.completed)
                                    
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    ProtocolsView()
        .environmentObject(AppState())
}
