import SwiftUI

struct CleaningRunWorkflow: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CleaningRunWorkflowViewModel(authService: AuthService())
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                workflowContent
            }
            .navigationTitle(viewModel.workflowTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { cancelToolbarItem }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Submit Cleaning Run", isPresented: $viewModel.showingSubmitConfirmation) {
            Button("Submit", role: .destructive) {
                viewModel.submitCleaningRun()
            }
            .disabled(viewModel.isSubmitting)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you ready to submit this cleaning run? This action cannot be undone.")
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.deepNavy, Color.black]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    // MARK: - Workflow Content

    @ViewBuilder
    private var workflowContent: some View {
        switch viewModel.workflowState {
        case .scanning:
            ScanningPhaseView { result in
                viewModel.handleScanResult(result, availableProtocols: appState.protocols)
            }

        case .protocolSelection:
            if let scanResult = viewModel.scanResult {
                ProtocolSelectionPhaseView(
                    scanResult: scanResult,
                    protocols: appState.protocols
                ) { cleaningProtocol in
                    viewModel.startProtocol(cleaningProtocol)
                }
            }

        case .activeProtocol:
            if let cleaningProtocol = viewModel.selectedProtocol,
               let scanResult = viewModel.scanResult {
                ActiveProtocolPhaseView(
                    cleaningProtocol: cleaningProtocol,
                    scanResult: scanResult,
                    completedSteps: $viewModel.completedSteps,
                    stepNotes: $viewModel.stepNotes
                ) {
                    viewModel.proceedToReview()
                }
            }

        case .review:
            if let cleaningProtocol = viewModel.selectedProtocol,
               let scanResult = viewModel.scanResult {
                ReviewPhaseView(
                    cleaningProtocol: cleaningProtocol,
                    scanResult: scanResult,
                    completedSteps: viewModel.completedSteps,
                    stepNotes: viewModel.stepNotes
                ) {
                    viewModel.confirmSubmit()
                }
            }

        case .completed:
            CompletedPhaseView {
                viewModel.resetWorkflow()
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var cancelToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if viewModel.canCancel {
                Button("Cancel") {
                    viewModel.resetWorkflow()
                }
                .foregroundColor(.accentText)
            }
        }
    }
}

// MARK: - Scanning Phase View
struct ScanningPhaseView: View {
    let onScanComplete: (ScanResult) -> Void
    @StateObject private var qrManager = QRManager()
    @StateObject private var scannerService = ScannerService()
    @State private var scanMode: ScanMode = .qr
    
    enum ScanMode: String, CaseIterable {
        case qr = "QR Code"
        case nfc = "NFC Tag"
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.neonAqua)
                    .shadow(color: .neonAqua.opacity(0.5), radius: 10)
                
                Text("Scan Area to Start")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Scan a QR code or NFC tag to begin the cleaning workflow")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Scan Mode Selector
            HStack(spacing: 12) {
                ForEach(ScanMode.allCases, id: \.self) { mode in
                    Button(action: {
                        scanMode = mode
                    }) {
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                scanMode == mode ? Color.neonAqua : Color.glassBackground
                            )
                            .foregroundColor(
                                scanMode == mode ? Color.deepNavy : Color.primaryText
                            )
                            .clipShape(Capsule())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Scanner View
            if scanMode == .qr {
                QRScannerView(qrManager: qrManager) { result in
                    handleQRResult(result)
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                NFCScannerPlaceholder()
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
            
            // Instructions
            VStack(spacing: 12) {
                Text(scanMode == .qr ? "QR Code Instructions" : "NFC Instructions")
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 8) {
                    if scanMode == .qr {
                        InstructionItem(icon: "qrcode", text: "Position QR code within frame")
                        InstructionItem(icon: "hand.tap", text: "Hold steady for detection")
                        InstructionItem(icon: "checkmark.circle", text: "Wait for confirmation")
                    } else {
                        InstructionItem(icon: "antenna.radiowaves.left.and.right", text: "Hold iPhone near NFC tag")
                        InstructionItem(icon: "touchid", text: "Keep close until detected")
                        InstructionItem(icon: "checkmark.circle", text: "Confirm area information")
                    }
                }
            }
            .padding()
            .glassCard()
        }
        .padding()
    }
    
    private func handleQRResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let qrData):
            let validation = qrManager.validateQRCode(qrData)
            if validation.isValid {
                let scanResult = ScanResult(
                    type: .qr,
                    areaId: validation.areaId!,
                    protocolId: validation.protocolId,
                    areaName: "Area \(validation.areaId!)",
                    protocolName: validation.protocolId != nil ? "Protocol \(validation.protocolId!)" : nil,
                    timestamp: Date(),
                    isValid: true
                )
                onScanComplete(scanResult)
                
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            }
        case .failure(let error):
            // Handle QR scan error appropriately in production
            break
        }
    }
}

// MARK: - Protocol Selection Phase View
struct ProtocolSelectionPhaseView: View {
    let scanResult: ScanResult
    let protocols: [CleaningProtocol]
    let onProtocolSelected: (CleaningProtocol) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 60))
                    .foregroundColor(.neonAqua)
                
                Text("Select Cleaning Protocol")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Area: \(scanResult.areaName)")
                    .font(.subheadline)
                    .foregroundColor(.accentText)
            }
            .padding(.top, 40)
            
            // Protocol List
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(protocols) { cleaningProtocol in
                        ProtocolSelectionCard(cleaningProtocol: cleaningProtocol) {
                            onProtocolSelected(cleaningProtocol)
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Active Protocol Phase View
struct ActiveProtocolPhaseView: View {
    let cleaningProtocol: CleaningProtocol
    let scanResult: ScanResult
    @Binding var completedSteps: Set<String>
    @Binding var stepNotes: [String: String]
    let onComplete: () -> Void
    
    @State private var currentStepIndex = 0
    @State private var showingStepNotes = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Progress Header
            VStack(spacing: 16) {
                Text("Cleaning in Progress")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("\(scanResult.areaName) • \(cleaningProtocol.name)")
                    .font(.subheadline)
                    .foregroundColor(.accentText)
                
                // Progress Bar
                VStack(spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Spacer()
                        
                        Text("\(completedSteps.count) of \(cleaningProtocol.steps.count) steps")
                            .font(.caption)
                            .foregroundColor(.accentText)
                    }
                    
                    ProgressView(value: Double(completedSteps.count), total: Double(cleaningProtocol.steps.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: .neonAqua))
                }
            }
            .padding()
            .glassCard()
            
            // Current Step
            if currentStepIndex < cleaningProtocol.steps.count {
                let currentStep = cleaningProtocol.steps[currentStepIndex]
                let isCompleted = completedSteps.contains(currentStep.id)
                
                ActiveStepCard(
                    step: currentStep,
                    isCompleted: isCompleted,
                    note: stepNotes[cleaningProtocol.steps[currentStepIndex].id] ?? ""
                ) { note in
                    stepNotes[cleaningProtocol.steps[currentStepIndex].id] = note
                }
                
                // Action Buttons
                HStack(spacing: 16) {
                    if !isCompleted {
                        Button(action: {
                            completeStep(currentStep)
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
                    }
                    
                    Button(action: {
                        showingStepNotes = true
                    }) {
                        HStack {
                            Image(systemName: "note.text")
                                .font(.title2)
                            
                            Text("Add Note")
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
                }
                .padding()
                .glassCard()
            }
            
            // Step Navigation
            if currentStepIndex > 0 || currentStepIndex < cleaningProtocol.steps.count - 1 {
                HStack {
                    Button(action: {
                        if currentStepIndex > 0 {
                            currentStepIndex -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .foregroundColor(.neonAqua)
                    }
                    .disabled(currentStepIndex == 0)
                    
                    Spacer()
                    
                    Button(action: {
                        if currentStepIndex < cleaningProtocol.steps.count - 1 {
                            currentStepIndex += 1
                        }
                    }) {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .foregroundColor(.neonAqua)
                    }
                    .disabled(currentStepIndex == cleaningProtocol.steps.count - 1)
                }
                .padding()
            }
            
            // Complete Button
            if completedSteps.count == cleaningProtocol.steps.count {
                Button(action: onComplete) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title2)
                        
                        Text("Review & Submit")
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
                .padding()
            }
        }
        .sheet(isPresented: $showingStepNotes) {
            if currentStepIndex < cleaningProtocol.steps.count {
                StepNotesView(
                    step: cleaningProtocol.steps[currentStepIndex],
                    note: stepNotes[cleaningProtocol.steps[currentStepIndex].id] ?? ""
                ) { note in
                    stepNotes[cleaningProtocol.steps[currentStepIndex].id] = note
                }
            }
        }
    }
    
    private func completeStep(_ step: CleaningStep) {
        completedSteps.insert(step.id)
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Move to next step if available
        if currentStepIndex < cleaningProtocol.steps.count - 1 {
            currentStepIndex += 1
        }
    }
}

// MARK: - Review Phase View
struct ReviewPhaseView: View {
    let cleaningProtocol: CleaningProtocol
    let scanResult: ScanResult
    let completedSteps: Set<String>
    let stepNotes: [String: String]
    let onSubmit: () -> Void
    var complianceScore: Double {
        let requiredSteps = cleaningProtocol.steps.filter { $0.required }
        let completedRequiredSteps = requiredSteps.filter { completedSteps.contains($0.id) }
        
        if requiredSteps.isEmpty {
            guard !cleaningProtocol.steps.isEmpty else { return 100.0 }
            return (Double(completedSteps.count) / Double(cleaningProtocol.steps.count)) * 100
        } else {
            return (Double(completedRequiredSteps.count) / Double(requiredSteps.count)) * 100
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.successGreen)
                    
                    Text("Review Cleaning Run")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text("Please review before submitting")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                .padding(.top, 40)
                
                // Summary Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Summary")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    VStack(spacing: 12) {
                        ReviewRow(title: "Area", value: scanResult.areaName)
                        ReviewRow(title: "Protocol", value: cleaningProtocol.name)
                        ReviewRow(title: "Completed Steps", value: "\(completedSteps.count) of \(cleaningProtocol.steps.count)")
                        ReviewRow(title: "Compliance Score", value: "\(Int(complianceScore))%")
                        ReviewRow(title: "Verification Method", value: scanResult.type == .qr ? "QR Code" : "NFC Tag")
                    }
                }
                .padding()
                .glassCard()
                
                // Steps Review
                VStack(alignment: .leading, spacing: 16) {
                    Text("Steps Completed")
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    VStack(spacing: 12) {
                        ForEach(Array(cleaningProtocol.steps.enumerated()), id: \.element.id) { index, step in
                            StepReviewRow(
                                stepNumber: index + 1,
                                step: step,
                                isCompleted: completedSteps.contains(step.id),
                                note: stepNotes[step.id]
                            )
                        }
                    }
                }
                .padding()
                .glassCard()
                
                // Submit Button
                Button(action: onSubmit) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        
                        Text("Submit Cleaning Run")
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
                .padding(.bottom, 20)
            }
            .padding()
        }
    }
}

// MARK: - Completed Phase View
struct CompletedPhaseView: View {
    let onNewRun: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // Success Animation
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.successGreen)
                    .shadow(color: .successGreen.opacity(0.5), radius: 10)
                
                Text("Cleaning Run Complete!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primaryText)
                
                Text("Your cleaning run has been successfully submitted and saved to the system.")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Action Buttons
            VStack(spacing: 16) {
                Button(action: onNewRun) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        
                        Text("Start New Cleaning Run")
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
                    // Navigate to dashboard
                }) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.title2)
                        
                        Text("View Dashboard")
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
            }
            .padding(.bottom, 20)
        }
        .padding()
    }
}

// MARK: - Supporting Views
struct InstructionItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.neonAqua)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primaryText)
            
            Spacer()
        }
    }
}

struct ProtocolSelectionCard: View {
    let cleaningProtocol: CleaningProtocol
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(cleaningProtocol.name)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    Spacer()
                    
                    priorityBadge
                }
                
                Text(cleaningProtocol.description)
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.accentText)
                    
                    Text("\(Int(cleaningProtocol.requiredDuration / 60)) min")
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
            }
            .padding()
            .glassCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var priorityBadge: some View {
        Group {
            if let priority = cleaningProtocol.priority {
                Text(priority.rawValue.capitalized)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(priorityColor.opacity(0.2))
                    .foregroundColor(priorityColor)
                    .clipShape(Capsule())
            } else {
                EmptyView()
            }
        }
    }

    private var priorityColor: Color {
        guard let priority = cleaningProtocol.priority else { return .secondaryText }
        switch priority {
        case .critical: return .errorRed
        case .high: return .warningYellow
        case .medium: return .neonAqua
        case .low: return .secondaryText
        }
    }
}

struct ActiveStepCard: View {
    let step: CleaningStep
    let isCompleted: Bool
    let note: String
    let onNoteChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(step.name)
                        .font(.headline)
                        .foregroundColor(.primaryText)
                    
                    if step.required {
                        Text("Required Step")
                            .font(.caption)
                            .foregroundColor(.errorRed)
                    }
                }
                
                Spacer()
                
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .successGreen : .secondaryText)
            }
            
            Text(step.description)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            if !step.equipment.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Equipment Needed:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(step.equipment, id: \.self) { equipment in
                            HStack(spacing: 8) {
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
            
            if !step.chemicals.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chemicals Required:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(step.chemicals, id: \.self) { chemical in
                            HStack(spacing: 8) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                    .foregroundColor(.warningYellow)
                                
                                Text(chemical)
                                    .font(.caption)
                                    .foregroundColor(.primaryText)
                            }
                        }
                    }
                }
            }
            
            if !step.checklistItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Checklist:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentText)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(step.checklistItems, id: \.self) { item in
                            HStack(spacing: 8) {
                                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.caption)
                                    .foregroundColor(isCompleted ? .successGreen : .secondaryText)
                                
                                Text(item)
                                    .font(.caption)
                                    .foregroundColor(.primaryText)
                                    .strikethrough(isCompleted)
                            }
                        }
                    }
                }
            }
            
            if !note.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentText)
                    
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.primaryText)
                        .padding(8)
                        .background(Color.glassBackground)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct ReviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primaryText)
        }
    }
}

struct StepReviewRow: View {
    let stepNumber: Int
    let step: CleaningStep
    let isCompleted: Bool
    let note: String?
    
    var body: some View {
        HStack(spacing: 12) {
            // Step Number
            Text("\(stepNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(isCompleted ? .white : .primaryText)
                .frame(width: 30, height: 30)
                .background(isCompleted ? Color.successGreen : Color.glassBackground)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                if let note = note, !note.isEmpty {
                    Text("Note: \(note)")
                        .font(.caption)
                        .foregroundColor(.accentText)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundColor(isCompleted ? .successGreen : .secondaryText)
        }
        .padding(.vertical, 8)
    }
}

struct StepNotesView: View {
    let step: CleaningStep
    @State private var note: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) var dismiss
    
    init(step: CleaningStep, note: String, onSave: @escaping (String) -> Void) {
        self.step = step
        self._note = State(initialValue: note)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("Add Notes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryText)
                    
                    Text(step.name)
                        .font(.subheadline)
                        .foregroundColor(.accentText)
                }
                .padding(.top, 20)
                
                // Notes Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notes for this step:")
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                    
                    TextEditor(text: $note)
                        .frame(minHeight: 150)
                        .padding()
                        .background(Color.glassBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.glassBorder, lineWidth: 1)
                        )
                        .cornerRadius(12)
                        .foregroundColor(.primaryText)
                }
                
                Spacer()
                
                // Save Button
                Button(action: {
                    onSave(note)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        
                        Text("Save Notes")
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
                .padding(.bottom, 20)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.deepNavy,
                        Color.black
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Step Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NFCScannerPlaceholder: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundColor(.neonAqua)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: true)
            
            Text("NFC Scanner")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
            
            Text("Hold iPhone near NFC tag")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .background(Color.glassBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.neonAqua, lineWidth: 2)
        )
    }
}

#Preview {
    CleaningRunWorkflow()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
