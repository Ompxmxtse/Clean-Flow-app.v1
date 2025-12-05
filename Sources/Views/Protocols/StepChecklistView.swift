import SwiftUI

struct StepChecklistView: View {
    let cleaningProtocol: CleaningProtocol
    @State private var completedSteps: Set<String> = []
    @State private var stepNotes: [String: String] = [:]
    @State private var showingNotesForStep: CleaningStep?
    @State private var currentStepIndex = 0

    @State private var showingCompletionAlert = false
    let onComplete: (Set<String>, [String: String]) -> Void
    
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
                    // Progress Header
                    progressHeader
                    
                    // Current Step
                    if currentStepIndex < cleaningProtocol.steps.count {
                        currentStepView
                    }
                    
                    // Step Navigation
                    stepNavigation
                    
                    // Complete Button
                    if completedSteps.count == cleaningProtocol.steps.count {
                        completeButton
                    }
                }
            }
            .navigationTitle("Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        // Handle cancel
                    }
                    .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(item: $showingNotesForStep) { step in
            StepNotesView(
                step: step,
                note: stepNotes[step.id] ?? ""
            ) { note in
                stepNotes[step.id] = note
            }
        }
        .alert("Protocol Complete", isPresented: $showingCompletionAlert) {
            Button("Submit") {
                onComplete(completedSteps, stepNotes)
            }
            Button("Continue", role: .cancel) { }
        } message: {
            Text("All steps completed. Ready to submit this cleaning protocol?")
        }
    }
    
    // MARK: - Progress Header
    private var progressHeader: some View {
        VStack(spacing: 16) {
            Text(cleaningProtocol.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            // Progress Bar
            VStack(spacing: 8) {
                HStack {
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    Spacer()
                    
                    Text("\(completedSteps.count) of \(cleaningProtocol.steps.count)")
                        .font(.caption)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
                
                ProgressView(value: Double(completedSteps.count), total: Double(cleaningProtocol.steps.count))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 43/255, green: 203/255, blue: 255/255)))
                    .scaleEffect(y: 1.5)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
    
    // MARK: - Current Step View
    private var currentStepView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Step Header
                VStack(spacing: 12) {
                    Text("Step \(currentStepIndex + 1) of \(cleaningProtocol.steps.count)")
                        .font(.headline)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                    
                    if let currentStep = getCurrentStep() {
                        Text(currentStep.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if currentStep.required {
                            Text("Required Step")
                                .font(.caption)
                                .foregroundColor(Color(red: 255/255, green: 100/255, blue: 100/255))
                        }
                    }
                }
                .padding(.top, 20)
                
                // Step Details
                if let currentStep = getCurrentStep() {
                    StepDetailView(
                        step: currentStep,
                        isCompleted: completedSteps.contains(currentStep.id),
                        note: stepNotes[currentStep.id]
                    ) { action in
                        handleStepAction(action, for: currentStep)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Step Navigation
    private var stepNavigation: some View {
        HStack(spacing: 20) {
            Button(action: {
                if currentStepIndex > 0 {
                    currentStepIndex -= 1
                }
            }) {
                HStack {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                    
                    Text("Previous")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            .disabled(currentStepIndex == 0)
            
            Button(action: {
                if currentStepIndex < cleaningProtocol.steps.count - 1 {
                    currentStepIndex += 1
                }
            }) {
                HStack {
                    Text("Next")
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(16)
            }
            .disabled(currentStepIndex == cleaningProtocol.steps.count - 1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Complete Button
    private var completeButton: some View {
        Button(action: {
            showingCompletionAlert = true
        }) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title2)
                
                Text("Complete Protocol")
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
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Helper Methods
    private func getCurrentStep() -> CleaningStep? {
        guard currentStepIndex < cleaningProtocol.steps.count else { return nil }
        return cleaningProtocol.steps[currentStepIndex]
    }
    
    private func handleStepAction(_ action: StepAction, for step: CleaningStep) {
        switch action {
        case .complete:
            completedSteps.insert(step.id)
            impactFeedback.impactOccurred()
            
        case .addNotes:
            showingNotesForStep = step
        }
    }
}

// MARK: - Step Detail View
struct StepDetailView: View {
    let step: CleaningStep
    let isCompleted: Bool
    let note: String?
    let onAction: (StepAction) -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Description
            VStack(alignment: .leading, spacing: 12) {
                Text("Description")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(step.description)
                    .font(.subheadline)
                    .foregroundColor(Color.white.opacity(0.8))
                    .multilineTextAlignment(.leading)
            }
            
            // Equipment
            if !step.equipment.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Equipment")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(step.equipment, id: \.self) { equipment in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 100/255, green: 255/255, blue: 100/255))
                                
                                Text(equipment)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            
            // Chemicals
            if !step.chemicals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required Chemicals")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(step.chemicals, id: \.self) { chemical in
                            HStack(spacing: 12) {
                                Image(systemName: "drop.fill")
                                    .font(.caption)
                                    .foregroundColor(Color(red: 255/255, green: 200/255, blue: 100/255))
                                
                                Text(chemical)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
            }
            
            // Checklist
            if !step.checklistItems.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Checklist")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(step.checklistItems, id: \.self) { item in
                            HStack(spacing: 12) {
                                Image(systemName: isCompleted ? "checkmark.square.fill" : "square")
                                    .font(.caption)
                                    .foregroundColor(isCompleted ? Color(red: 100/255, green: 255/255, blue: 100/255) : Color.white.opacity(0.6))
                                
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                    .strikethrough(isCompleted)
                            }
                        }
                    }
                }
            }
            
            // Notes
            if let note = note, !note.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Notes")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(note)
                        .font(.subheadline)
                        .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: {
                    onAction(.toggleComplete)
                }) {
                    HStack {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                        
                        Text(isCompleted ? "Step Completed" : "Complete Step")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        isCompleted ? Color(red: 100/255, green: 255/255, blue: 100/255).opacity(0.2) : Color.white.opacity(0.1)
                    )
                    .foregroundColor(isCompleted ? Color(red: 100/255, green: 255/255, blue: 100/255) : .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isCompleted ? Color(red: 100/255, green: 255/255, blue: 100/255) : Color.white.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                    .cornerRadius(16)
                }
                
                Button(action: {
                    onAction(.addNotes)
                }) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.title2)
                        
                        Text("Add Notes")
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
            }
        }
        .padding(20)
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

// MARK: - Step Action Enum
enum StepAction {
    case toggleComplete
    case addNotes
}

#Preview {
    StepChecklistView(cleaningProtocol: .mock) { completedSteps, notes in
        // Preview callback
    }
}
