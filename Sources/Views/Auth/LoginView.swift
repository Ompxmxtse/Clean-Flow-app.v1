import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthService
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingPasswordReset = false
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            CleanFlowTheme.background.ignoresSafeArea()
            
            // Animated background elements
            AnimatedBackgroundView()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Logo Section
                    VStack(spacing: 16) {
                        NeonCLogoView()
                            .frame(width: 80, height: 80)
                        
                        Text("Clean-Flow")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(CleanFlowTheme.accentGradient)
                            .shadow(color: CleanFlowTheme.neonBlue.opacity(0.6), radius: 12)
                        
                        Text("Medical Compliance System")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CleanFlowTheme.textSecondary)
                    }
                                // Login Form
                    VStack(spacing: 16) {
                        CustomTextField(
                            icon: "envelope",
                            placeholder: "Email",
                            text: $email
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        
                        CustomSecureField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $password
                        )
                        
                        if showError {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                        
                        Button {
                            signIn()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(CleanFlowTheme.accentGradient)
                            .cornerRadius(16)
                            .shadow(color: CleanFlowTheme.neonBlue.opacity(0.5), radius: 15)
                        }
                        .disabled(isLoading)
                        
                        HStack(spacing: 16) {
                            Button("Forgot Password?") {
                                showingPasswordReset = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CleanFlowTheme.neonCyan)
                            
                            Button("Register") {
                                showingRegistration = true
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CleanFlowTheme.neonCyan)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    // Footer
                    Text("v1.0.0 • Secure & Compliant")
                        .font(.caption2)
                        .foregroundColor(CleanFlowTheme.textSecondary.opacity(0.5))
                        .padding(.bottom, 32)
                }
            }
        }
        .sheet(isPresented: $showingRegistration) {
            RegistrationView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showingPasswordReset) {
            PasswordResetView()
                .environmentObject(authService)
        }
    }
    
    private func signIn() {
        isLoading = true
        showError = false
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch {
                await MainActor.run {
                    errorMessage = "Invalid credentials. Please try again."
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthService())
}
