import Foundation
import LocalAuthentication
import Combine

// MARK: - Biometric Auth Service
// Face ID / Touch ID authentication service

class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()

    @Published var isBiometricAvailable = false
    @Published var biometricType: BiometricType = .none
    @Published var isAuthenticated = false
    @Published var errorMessage: String?

    private let context = LAContext()
    private let userDefaults = UserDefaults.standard

    private let biometricEnabledKey = "biometricAuthEnabled"
    private let biometricUserIdKey = "biometricUserId"

    enum BiometricType {
        case none
        case touchID
        case faceID

        var displayName: String {
            switch self {
            case .none: return "Not Available"
            case .touchID: return "Touch ID"
            case .faceID: return "Face ID"
            }
        }

        var icon: String {
            switch self {
            case .none: return "lock.fill"
            case .touchID: return "touchid"
            case .faceID: return "faceid"
            }
        }
    }

    enum BiometricError: LocalizedError {
        case notAvailable
        case notEnrolled
        case authenticationFailed
        case userCancelled
        case passcodeNotSet
        case biometryLockout
        case invalidContext
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data enrolled. Please set up Face ID or Touch ID in Settings"
            case .authenticationFailed:
                return "Authentication failed. Please try again"
            case .userCancelled:
                return "Authentication was cancelled"
            case .passcodeNotSet:
                return "Device passcode is not set. Please set a passcode in Settings"
            case .biometryLockout:
                return "Biometric authentication is locked. Please use your passcode"
            case .invalidContext:
                return "Authentication context is invalid"
            case .unknown(let error):
                return error.localizedDescription
            }
        }
    }

    // MARK: - Initialization

    private init() {
        checkBiometricAvailability()
    }

    // MARK: - Public Methods

    /// Check if biometric authentication is available
    func checkBiometricAvailability() {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)

        DispatchQueue.main.async {
            self.isBiometricAvailable = canEvaluate

            if canEvaluate {
                switch self.context.biometryType {
                case .touchID:
                    self.biometricType = .touchID
                case .faceID:
                    self.biometricType = .faceID
                case .opticID:
                    self.biometricType = .faceID // Treat optic ID as Face ID for now
                case .none:
                    self.biometricType = .none
                @unknown default:
                    self.biometricType = .none
                }
            } else {
                self.biometricType = .none
            }
        }
    }

    /// Authenticate user with biometrics
    func authenticate(reason: String = "Authenticate to access Clean-Flow") async -> Result<Bool, BiometricError> {
        let context = LAContext()
        context.localizedCancelTitle = "Use Password"
        context.localizedFallbackTitle = "Enter Password"

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if let laError = error as? LAError {
                return .failure(mapLAError(laError))
            }
            return .failure(.notAvailable)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )

            await MainActor.run {
                self.isAuthenticated = success
                self.errorMessage = nil
            }

            return .success(success)
        } catch let error as LAError {
            let biometricError = mapLAError(error)
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = biometricError.errorDescription
            }
            return .failure(biometricError)
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = error.localizedDescription
            }
            return .failure(.unknown(error))
        }
    }

    /// Authenticate with fallback to device passcode
    func authenticateWithPasscodeFallback(reason: String = "Authenticate to access Clean-Flow") async -> Result<Bool, BiometricError> {
        let context = LAContext()

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )

            await MainActor.run {
                self.isAuthenticated = success
                self.errorMessage = nil
            }

            return .success(success)
        } catch let error as LAError {
            let biometricError = mapLAError(error)
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = biometricError.errorDescription
            }
            return .failure(biometricError)
        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.errorMessage = error.localizedDescription
            }
            return .failure(.unknown(error))
        }
    }

    // MARK: - Biometric Settings Management

    /// Check if biometric login is enabled for current user
    var isBiometricEnabled: Bool {
        return userDefaults.bool(forKey: biometricEnabledKey)
    }

    /// Get the user ID associated with biometric login
    var biometricUserId: String? {
        return userDefaults.string(forKey: biometricUserIdKey)
    }

    /// Enable biometric login for a user
    func enableBiometric(for userId: String) async -> Result<Bool, BiometricError> {
        // First authenticate to confirm user identity
        let result = await authenticate(reason: "Confirm identity to enable \(biometricType.displayName)")

        switch result {
        case .success(let authenticated):
            if authenticated {
                userDefaults.set(true, forKey: biometricEnabledKey)
                userDefaults.set(userId, forKey: biometricUserIdKey)
                return .success(true)
            }
            return .success(false)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// Disable biometric login
    func disableBiometric() {
        userDefaults.removeObject(forKey: biometricEnabledKey)
        userDefaults.removeObject(forKey: biometricUserIdKey)
    }

    /// Attempt biometric login if enabled
    func attemptBiometricLogin() async -> Result<String?, BiometricError> {
        guard isBiometricEnabled, let userId = biometricUserId else {
            return .success(nil)
        }

        let result = await authenticate(reason: "Sign in to Clean-Flow")

        switch result {
        case .success(let authenticated):
            if authenticated {
                return .success(userId)
            }
            return .success(nil)
        case .failure(let error):
            return .failure(error)
        }
    }

    // MARK: - Private Methods

    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel, .appCancel, .systemCancel:
            return .userCancelled
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryLockout:
            return .biometryLockout
        case .invalidContext:
            return .invalidContext
        default:
            return .unknown(error)
        }
    }
}

// MARK: - SwiftUI Integration

import SwiftUI

struct BiometricLoginButton: View {
    @ObservedObject var biometricService = BiometricAuthService.shared
    let onSuccess: (String) -> Void
    let onFailure: (BiometricAuthService.BiometricError) -> Void

    @State private var isAuthenticating = false

    var body: some View {
        Button {
            Task {
                isAuthenticating = true
                let result = await biometricService.attemptBiometricLogin()
                isAuthenticating = false

                switch result {
                case .success(let userId):
                    if let userId = userId {
                        onSuccess(userId)
                    }
                case .failure(let error):
                    onFailure(error)
                }
            }
        } label: {
            HStack(spacing: 12) {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: biometricService.biometricType.icon)
                        .font(.title2)
                }

                Text("Sign in with \(biometricService.biometricType.displayName)")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .disabled(!biometricService.isBiometricAvailable || !biometricService.isBiometricEnabled || isAuthenticating)
        .opacity(biometricService.isBiometricAvailable && biometricService.isBiometricEnabled ? 1.0 : 0.5)
    }
}

struct BiometricToggle: View {
    @ObservedObject var biometricService = BiometricAuthService.shared
    let userId: String
    @State private var isEnabled: Bool
    @State private var isProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(userId: String) {
        self.userId = userId
        self._isEnabled = State(initialValue: BiometricAuthService.shared.isBiometricEnabled)
    }

    var body: some View {
        Toggle(isOn: $isEnabled) {
            HStack(spacing: 12) {
                Image(systemName: biometricService.biometricType.icon)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign in with \(biometricService.biometricType.displayName)")
                        .font(.subheadline)

                    Text("Use biometric authentication for quick access")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .disabled(!biometricService.isBiometricAvailable || isProcessing)
        .onChange(of: isEnabled) { _, newValue in
            Task {
                isProcessing = true
                if newValue {
                    let result = await biometricService.enableBiometric(for: userId)
                    switch result {
                    case .success(let enabled):
                        if !enabled {
                            isEnabled = false
                        }
                    case .failure(let error):
                        isEnabled = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                } else {
                    biometricService.disableBiometric()
                }
                isProcessing = false
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}
