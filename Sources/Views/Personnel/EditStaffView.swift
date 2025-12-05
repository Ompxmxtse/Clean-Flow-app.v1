import SwiftUI

// MARK: - EditStaffView
// Placeholder view for editing staff member details
struct EditStaffView: View {
    let user: User
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var department: String = ""
    @State private var selectedRole: User.UserRole = .cleaner
    @State private var isActive: Bool = true

    init(user: User) {
        self.user = user
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email)
        _department = State(initialValue: user.department)
        _selectedRole = State(initialValue: user.role)
        _isActive = State(initialValue: user.isActive)
    }

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
                    VStack(spacing: 20) {
                        // Profile section
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color(red: 43/255, green: 203/255, blue: 255/255).opacity(0.2))
                                    .frame(width: 100, height: 100)

                                Text(String(name.prefix(2)).uppercased())
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                            }
                        }
                        .padding(.top, 20)

                        // Form fields
                        VStack(spacing: 16) {
                            formField(title: "Name", text: $name)
                            formField(title: "Email", text: $email)
                            formField(title: "Department", text: $department)

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

                            // Active toggle
                            Toggle(isOn: $isActive) {
                                Text("Active")
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)

                        // Save button
                        Button(action: saveChanges) {
                            Text("Save Changes")
                                .fontWeight(.semibold)
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
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Edit Profile")
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

    private func formField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))

            TextField("", text: text)
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .foregroundColor(.white)
        }
    }

    private func saveChanges() {
        // TODO: Implement save logic with FirestoreRepository
        dismiss()
    }
}

#Preview {
    EditStaffView(user: User.mock)
}
