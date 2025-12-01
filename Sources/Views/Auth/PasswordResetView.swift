import SwiftUI

struct PasswordResetView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var emailSent = false
    
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
                
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge")
                            .font(.system(size: 60))
                            .foregroundColor(.neonAqua)
                        
                        if !emailSent {
                            Text("Reset Password")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Enter your email address and we'll send you instructions to reset your password")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Email Sent")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.successGreen)
                            
                            Text("Check your email for password reset instructions")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.top, 40)
                    
                    if !emailSent {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.accentText)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(CleanFlowTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        .padding(.horizontal, 20)
                        
                        // Reset Button
                        Button(action: {
                            authService.resetPassword(email: email)
                            emailSent = true
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text("Send Reset Email")
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
                        .disabled(authService.isLoading || email.isEmpty)
                        .padding(.horizontal, 20)
                    } else {
                        // Done Button
                        Button("Back to Login") {
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.successGreen, .successGreen.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .successGreen.opacity(0.3), radius: 8)
                        .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Reset Password")
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
        .alert("Error", isPresented: .constant(authService.errorMessage != nil), actions: {
            Button("OK") {
                authService.errorMessage = nil
            }
        }, message: {
            if let errorMessage = authService.errorMessage {
                Text(errorMessage)
            }
        })
    }
}

#Preview {
    PasswordResetView()
        .environmentObject(AuthService())
}
