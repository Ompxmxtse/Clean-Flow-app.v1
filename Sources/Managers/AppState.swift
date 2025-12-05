import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var currentUser: User?
    @Published var selectedTab: TabItem = .dashboard
    @Published var isLoading = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = ""
    
    // Dashboard state
    @Published var dashboardStats: DashboardStats?
    @Published var recentRuns: [CleaningRun] = []
    @Published var protocols: [CleaningProtocol] = []
    
    // Scanner state
    @Published var isScanning = false
    @Published var lastScanResult: ScanResult?
    
    // Protocol execution state
    @Published var activeCleaningRun: CleaningRun?
    @Published var currentStepIndex = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    enum TabItem: String, CaseIterable {
        case dashboard = "Dashboard"
        case scanner = "Scanner"
        case protocols = "Protocols"
        case audits = "Audits"
        case personnel = "Personnel"
        case settings = "Settings"
        
        var iconName: String {
            switch self {
            case .dashboard: return "chart.bar.fill"
            case .scanner: return "qrcode"
            case .protocols: return "list.bullet.clipboard"
            case .audits: return "doc.text.magnifyingglass"
            case .personnel: return "person.2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        // Auto-refresh dashboard data
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshDashboardData()
            }
            .store(in: &cancellables)
    }
    
    func refreshDashboardData() {
        guard currentUser != nil else { return }
        
        isLoading = true
        let group = DispatchGroup()
        
        // Fetch dashboard stats
        group.enter()
        FirestoreRepository.shared.fetchDashboardStats { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let stats):
                    self?.dashboardStats = stats
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                    break
                }
                group.leave()
            }
        }
        
        // Fetch recent runs
        group.enter()
        FirestoreRepository.shared.fetchCleaningRunsToday { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let runs):
                    self?.recentRuns = runs
                case .failure(let error):
                    // Handle error appropriately in production
                    break
                }
                group.leave()
            }
        }
        
        // Fetch protocols
        group.enter()
        FirestoreRepository.shared.fetchProtocols { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let protocols):
                    self?.protocols = protocols
                case .failure(let error):
                    // Handle error appropriately in production
                    break
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.isLoading = false
        }
    }
    
    func showAlert(title: String, message: String) {
        self.alertTitle = title
        self.alertMessage = message
        self.showingAlert = true
    }
    
    func startCleaningProtocol(_ cleaningProtocol: CleaningProtocol, areaId: String, areaName: String) {
        guard let user = currentUser else { return }
        
        let cleaningRun = CleaningRun(
            id: UUID().uuidString,
            protocolId: cleaningProtocol.id,
            protocolName: cleaningProtocol.name,
            cleanerId: user.id,
            cleanerName: user.name,
            areaId: areaId,
            areaName: areaName,
            startTime: Date(),
            endTime: nil,
            status: .inProgress,
            verificationMethod: .manual,
            qrCode: nil,
            nfcTag: nil,
            steps: cleaningProtocol.steps.map { step in
                CompletedStep(
                    id: UUID().uuidString,
                    stepId: step.id,
                    name: step.name,
                    completed: false,
                    completedAt: nil,
                    completedBy: nil,
                    notes: nil,
                    checklistItems: step.checklistItems.enumerated().map { index, itemText in
                        CompletedChecklistItem(
                            id: UUID().uuidString,
                            item: ChecklistItem(id: "item-\(index)", text: itemText, isRequired: true),
                            completed: false,
                            completedAt: nil
                        )
                    }
                )
            },
            notes: nil,
            auditorId: nil,
            auditorName: nil,
            complianceScore: nil,
            createdAt: Date()
        )
        
        activeCleaningRun = cleaningRun
        currentStepIndex = 0
        
        // Save to Firestore
        FirestoreRepository.shared.saveCleaningRun(cleaningRun) { [weak self] result in
            switch result {
            case .success:
                // Cleaning run started successfully
                break
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Failed to start cleaning run: \(error.localizedDescription)")
                break
            }
        }
        
        // Navigate to protocols tab
        selectedTab = .protocols
    }
    
    func completeCurrentStep() {
        guard var run = activeCleaningRun,
              currentStepIndex < run.steps.count else { return }
        
        let user = currentUser
        
        // Update current step
        run.steps[currentStepIndex] = CompletedStep(
            id: run.steps[currentStepIndex].id,
            stepId: run.steps[currentStepIndex].stepId,
            name: run.steps[currentStepIndex].name,
            completed: true,
            completedAt: Date(),
            completedBy: user?.name,
            notes: run.steps[currentStepIndex].notes,
            checklistItems: run.steps[currentStepIndex].checklistItems.map { item in
                CompletedChecklistItem(
                    id: item.id,
                    item: item.item,
                    completed: true,
                    completedAt: Date()
                )
            }
        )
        
        activeCleaningRun = run
        
        // Save to Firestore
        FirestoreRepository.shared.saveCleaningRun(run) { [weak self] result in
            switch result {
            case .success:
                // Step completed successfully
                break
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Failed to complete step: \(error.localizedDescription)")
                break
            }
        }
        
        // Move to next step or complete run
        if currentStepIndex < run.steps.count - 1 {
            currentStepIndex += 1
        } else {
            completeCleaningRun()
        }
    }
    
    private func completeCleaningRun() {
        guard var run = activeCleaningRun else { return }
        
        run.endTime = Date()
        run.status = .completed
        
        // Calculate compliance score
        let completedSteps = run.steps.filter { $0.completed }.count
        let totalSteps = run.steps.count
        run.complianceScore = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) * 100 : 100.0
        
        activeCleaningRun = run
        
        // Save to Firestore
        FirestoreRepository.shared.saveCleaningRun(run) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.showAlert(title: "Success", message: "Cleaning protocol completed successfully!")
                    self?.activeCleaningRun = nil
                    self?.currentStepIndex = 0
                    self?.refreshDashboardData()
                    break
                case .failure(let error):
                    self?.showAlert(title: "Error", message: "Failed to complete cleaning run: \(error.localizedDescription)")
                    break
                }
            }
        }
    }
    
    func cancelCleaningRun() {
        guard var run = activeCleaningRun else { return }
        
        run.endTime = Date()
        run.status = .failed
        run.notes = "Cancelled by user"
        
        activeCleaningRun = nil
        currentStepIndex = 0
        
        FirestoreRepository.shared.saveCleaningRun(run) { [weak self] result in
            switch result {
            case .success:
                // Cleaning run cancelled
                self?.refreshDashboardData()
                break
            case .failure(let error):
                self?.showAlert(title: "Error", message: "Failed to cancel cleaning run: \(error.localizedDescription)")
                break
            }
        }
    }
}
