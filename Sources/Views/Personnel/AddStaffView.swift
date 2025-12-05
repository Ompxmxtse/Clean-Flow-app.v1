import SwiftUI

// MARK: - AddStaffView
// View for adding new staff members
struct AddStaffView: View {
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var department: String = ""
    @State private var selectedRole: User.UserRole = .cleaner
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

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

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))

                            Text("Add New Staff Member")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            formField(title: "Full Name", text: $name, placeholder: "Enter full name")
                            formField(title: "Email", text: $email, placeholder: "Enter email address", keyboardType: .emailAddress)
                            formField(title: "Department", text: $department, placeholder: "Enter department")

                            // Role picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Role")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.6))

                                Picker("Role", selection: $selectedRole) {
                                    ForEach(User.UserRole.allCases, id: \.self) { role in
                                        Text(role.rawValue.capitalized).tag(role)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)

                            secureFormField(title: "Password", text: $password, placeholder: "Enter password")
                            secureFormField(title: "Confirm Password", text: $confirmPassword, placeholder: "Confirm password")
                        }
                        .padding(.horizontal)

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                        }

                        // Add button
                        Button(action: addStaff) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "person.badge.plus")
                                    Text("Add Staff Member")
                                        .fontWeight(.semibold)
                                }
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
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Add Staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                }
            }
        }
    }

    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !department.isEmpty &&
        !password.isEmpty && password == confirmPassword && password.count >= 6
    }

    private func formField(title: String, text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textContentType(keyboardType == .emailAddress ? .emailAddress : .name)
                .autocapitalization(keyboardType == .emailAddress ? .none : .words)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }

    private func secureFormField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            SecureField(placeholder, text: text)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }

    private func addStaff() {
        guard isFormValid else {
            errorMessage = "Please fill in all fields correctly"
            return
        }

        isLoading = true
        errorMessage = nil

        // TODO: Implement actual user creation with AuthService
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
            dismiss()
        }
    }
}

#Preview {
    AddStaffView()
}
