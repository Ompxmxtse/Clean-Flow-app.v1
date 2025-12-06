import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var selectedRole: User.UserRole = .cleaner
    @State private var department = ""
    
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
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.neonAqua)
                            
                            Text("Create Account")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Join Clean-Flow to manage hospital cleaning")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Registration Form
                        VStack(spacing: 16) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .foregroundColor(.accentText)
                                
                                TextField("Enter your full name", text: $name)
                                    .cleanFlowTextField()
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.accentText)
                                
                                TextField("Enter your email", text: $email)
                                    .cleanFlowTextField()
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                            }
                            
                            // Department
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Department")
                                    .font(.subheadline)
                                    .foregroundColor(.accentText)
                                
                                TextField("Enter your department", text: $department)
                                    .cleanFlowTextField()
                            }
                            
                            // Role
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Role")
                                    .font(.subheadline)
                                    .foregroundColor(.accentText)
                                
                                Menu {
                                    ForEach(User.UserRole.allCases, id: \.self) { role in
                                        Button(role.rawValue.capitalized) {
                                            selectedRole = role
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(selectedRole.rawValue.capitalized)
                                            .foregroundColor(.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                            .foregroundColor(.secondaryText)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.05))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                            )
                                    )
                                }
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.accentText)
                                
                                SecureField("Enter your password", text: $password)
                                    .cleanFlowTextField()
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.accentText)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .cleanFlowTextField()
                            }
                        }
                        .padding()
                        .glassCard()
                        
                        // Register Button
                        Button(action: {
                            if isValidForm {
                                authService.signUp(
                                    email: email,
                                    password: password,
                                    name: name,
                                    role: selectedRole,
                                    department: department
                                )
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text("Create Account")
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
                        .disabled(authService.isLoading || !isValidForm)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Register")
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
    
    private var isValidForm: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        email.contains("@") && email.contains(".") &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !department.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        password == confirmPassword &&
        password.count >= 8
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthService())
}
