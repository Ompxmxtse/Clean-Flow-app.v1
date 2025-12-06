import Foundation
import SwiftUI
import UIKit

// MARK: - Delegate Protocol

protocol CleaningRunWorkflowDelegate: AnyObject {
    func workflowDidComplete()
    func workflowDidFail(with error: Error)
}

// MARK: - Workflow State

enum WorkflowState {
    case scanning
    case protocolSelection
    case activeProtocol
    case review
    case completed
}

// MARK: - ViewModel

@MainActor
class CleaningRunWorkflowViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var workflowState: WorkflowState = .scanning
    @Published var scanResult: ScanResult?
    @Published var selectedProtocol: CleaningProtocol?
    @Published var completedSteps: Set<String> = []
    @Published var stepNotes: [String: String] = [:]
    @Published var showingSubmitConfirmation = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    // MARK: - Delegate

    weak var delegate: CleaningRunWorkflowDelegate?

    // MARK: - Dependencies

    private let authService: AuthService
    private let repository: FirestoreRepository

    // MARK: - Computed Properties

    var workflowTitle: String {
        switch workflowState {
        case .scanning: return "Start Cleaning"
        case .protocolSelection: return "Select Protocol"
        case .activeProtocol: return "Cleaning in Progress"
        case .review: return "Review & Submit"
        case .completed: return "Cleaning Complete"
        }
    }

    var canCancel: Bool {
        workflowState != .scanning && workflowState != .completed
    }

    // MARK: - Initializer

    init(authService: AuthService, repository: FirestoreRepository = .shared) {
        self.authService = authService
        self.repository = repository
    }

    func updateAuthService(_ service: AuthService) {
        // Re-inject auth service from environment
    }

    // MARK: - Workflow Actions

    func handleScanResult(_ result: ScanResult, availableProtocols: [CleaningProtocol]) {
        scanResult = result

        if let protocolId = result.protocolId,
           let cleaningProtocol = availableProtocols.first(where: { $0.id == protocolId }) {
            startProtocol(cleaningProtocol)
        } else {
            workflowState = .protocolSelection
        }
    }

    func startProtocol(_ cleaningProtocol: CleaningProtocol) {
        selectedProtocol = cleaningProtocol
        completedSteps = []
        stepNotes = [:]
        workflowState = .activeProtocol
    }

    func completeStep(_ step: CleaningStep) {
        completedSteps.insert(step.id)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func addNote(for stepId: String, note: String) {
        stepNotes[stepId] = note
    }

    func proceedToReview() {
        workflowState = .review
    }

    func confirmSubmit() {
        showingSubmitConfirmation = true
    }

    func submitCleaningRun() {
        guard let user = authService.currentUser,
              let cleaningProtocol = selectedProtocol,
              let scanResult = scanResult else {
            errorMessage = "Missing required data"
            return
        }

        isSubmitting = true
        errorMessage = nil

        let cleaningRun = buildCleaningRun(
            user: user,
            cleaningProtocol: cleaningProtocol,
            scanResult: scanResult
        )

        repository.saveCleaningRun(cleaningRun) { [weak self] result in
            Task { @MainActor in
                self?.handleSubmitResult(result)
            }
        }
    }

    func resetWorkflow() {
        workflowState = .scanning
        scanResult = nil
        selectedProtocol = nil
        completedSteps = []
        stepNotes = [:]
        errorMessage = nil
    }

    // MARK: - Private Helpers

    private func buildCleaningRun(
        user: User,
        cleaningProtocol: CleaningProtocol,
        scanResult: ScanResult
    ) -> CleaningRun {
        let completedStepObjects = cleaningProtocol.steps
            .filter { completedSteps.contains($0.id) }
            .map { step in
                CompletedStep(
                    id: UUID().uuidString,
                    stepId: step.id,
                    name: step.name,
                    completed: true,
                    completedAt: Date(),
                    completedBy: user.name,
                    notes: stepNotes[step.id],
                    checklistItems: []
                )
            }

        return CleaningRun(
            id: UUID().uuidString,
            protocolId: cleaningProtocol.id,
            protocolName: cleaningProtocol.name,
            cleanerId: user.id,
            cleanerName: user.name,
            areaId: scanResult.areaId,
            areaName: scanResult.areaName,
            startTime: Date().addingTimeInterval(-Double(cleaningProtocol.steps.count * 300)),
            endTime: Date(),
            status: .completed,
            verificationMethod: scanResult.type == .qr ? .qrCode : .nfc,
            qrCode: scanResult.type == .qr ? "CF-AREA-\(scanResult.areaId)" : nil,
            nfcTag: scanResult.type == .nfc ? "NFC-\(scanResult.areaId)" : nil,
            steps: completedStepObjects,
            notes: nil,
            auditorId: nil,
            auditorName: nil,
            complianceScore: calculateComplianceScore(),
            createdAt: Date()
        )
    }

    private func handleSubmitResult(_ result: Result<Void, Error>) {
        isSubmitting = false

        switch result {
        case .success:
            workflowState = .completed
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            delegate?.workflowDidComplete()

        case .failure(let error):
            errorMessage = error.localizedDescription
            delegate?.workflowDidFail(with: error)
        }
    }

    func calculateComplianceScore() -> Double {
        guard let cleaningProtocol = selectedProtocol else { return 0 }

        let requiredSteps = cleaningProtocol.steps.filter { $0.required }
        let completedRequiredCount = requiredSteps.filter { completedSteps.contains($0.id) }.count

        if !requiredSteps.isEmpty {
            return (Double(completedRequiredCount) / Double(requiredSteps.count)) * 100
        } else {
            guard !cleaningProtocol.steps.isEmpty else { return 100 }
            return (Double(completedSteps.count) / Double(cleaningProtocol.steps.count)) * 100
        }
    }
}
