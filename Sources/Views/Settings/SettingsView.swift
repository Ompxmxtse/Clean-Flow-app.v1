import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var appState: AppState
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var hapticEnabled = true
    @State private var autoRefreshEnabled = true
    @State private var darkModeEnabled = true
    @State private var showingAbout = false
    @State private var showingHelp = false
    
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
                
                List {
                    // User Profile Section
                    userProfileSection
                    
                    // Notifications Section
                    notificationsSection
                    
                    // App Settings Section
                    appSettingsSection
                    
                    // Data & Storage Section
                    dataStorageSection
                    
                    // Support Section
                    supportSection
                    
                    // About Section
                    aboutSection
                    
                    // Sign Out Section
                    signOutSection
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingHelp) {
            HelpView()
        }
    }
    
    // MARK: - User Profile Section
    private var userProfileSection: some View {
        Section {
            if let user = authService.currentUser {
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color.neonAqua.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Text(String(user.name.prefix(2)).uppercased())
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.neonAqua)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(user.name)
                            .font(.headline)
                            .foregroundColor(.primaryText)
                        
                        Text(user.email)
                            .font(.caption)
                            .foregroundColor(.secondaryText)
                        
                        Text("\(user.role.rawValue.capitalized) • \(user.department)")
                            .font(.caption2)
                            .foregroundColor(.accentText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Profile")
                .foregroundColor(.accentText)
        }
        .listRowBackground(Color.glassBackground)
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        Section {
            SettingsToggleRow(
                title: "Push Notifications",
                subtitle: "Receive alerts for cleaning cycles",
                icon: "bell.fill",
                isOn: $notificationsEnabled
            )
            
            SettingsToggleRow(
                title: "Sound Effects",
                subtitle: "Play sounds for completed tasks",
                icon: "speaker.wave.3.fill",
                isOn: $soundEnabled
            )
            
            SettingsToggleRow(
                title: "Haptic Feedback",
                subtitle: "Vibrate on successful scans",
                icon: "iphone.radiowaves.left.and.right",
                isOn: $hapticEnabled
            )
        } header: {
            Text("Notifications")
                .foregroundColor(.accentText)
        } footer: {
            Text("Manage how Clean-Flow notifies you about important events")
                .font(.caption)
                .foregroundColor(.secondaryText)
        }
        .listRowBackground(Color.glassBackground)
    }
    
    // MARK: - App Settings Section
    private var appSettingsSection: some View {
        Section {
            SettingsToggleRow(
                title: "Auto Refresh",
                subtitle: "Automatically update dashboard data",
                icon: "arrow.clockwise",
                isOn: $autoRefreshEnabled
            )
            
            SettingsToggleRow(
                title: "Dark Mode",
                subtitle: "Use dark theme throughout the app",
                icon: "moon.fill",
                isOn: $darkModeEnabled
            )
            
            SettingsNavigationRow(
                title: "Language",
                subtitle: "English (US)",
                icon: "globe",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Units",
                subtitle: "Metric",
                icon: "ruler",
                destination: EmptyView()
            )
        } header: {
            Text("App Settings")
                .foregroundColor(.accentText)
        }
        .listRowBackground(Color.glassBackground)
    }
    
    // MARK: - Data & Storage Section
    private var dataStorageSection: some View {
        Section {
            SettingsNavigationRow(
                title: "Clear Cache",
                subtitle: "Free up storage space",
                icon: "trash.fill",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Export Data",
                subtitle: "Download your cleaning history",
                icon: "square.and.arrow.up.fill",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Backup Settings",
                subtitle: "Manage cloud backup preferences",
                icon: "icloud.fill",
                destination: EmptyView()
            )
        } header: {
            Text("Data & Storage")
                .foregroundColor(.accentText)
        }
        .listRowBackground(Color.glassBackground)
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        Section {
            SettingsNavigationRow(
                title: "Help Center",
                subtitle: "Get help with Clean-Flow",
                icon: "questionmark.circle.fill",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Contact Support",
                subtitle: "Reach out to our team",
                icon: "envelope.fill",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Privacy Policy",
                subtitle: "Read our privacy policy",
                icon: "lock.shield",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Terms of Service",
                subtitle: "Read our terms of service",
                icon: "doc.text.fill",
                destination: EmptyView()
            )
        } header: {
            Text("Support")
                .foregroundColor(.accentText)
        }
        .listRowBackground(Color.glassBackground)
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        Section {
            SettingsNavigationRow(
                title: "About Clean-Flow",
                subtitle: "Version 1.0.0",
                icon: "info.circle.fill",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "What's New",
                subtitle: "See the latest updates",
                icon: "star.fill",
                destination: EmptyView()
            )
            
            SettingsNavigationRow(
                title: "Rate App",
                subtitle: "Share your feedback",
                icon: "star.circle.fill",
                destination: EmptyView()
            )
        } header: {
            Text("About")
                .foregroundColor(.accentText)
        }
        .listRowBackground(Color.glassBackground)
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        Section {
            Button(action: {
                authService.signOut()
            }) {
                HStack {
                    Image(systemName: "arrow.right.square.fill")
                        .font(.title3)
                        .foregroundColor(.errorRed)
                        .frame(width: 24)
                    
                    Text("Sign Out")
                        .font(.subheadline)
                        .foregroundColor(.errorRed)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
            }
        } header: {
            Text("Account")
                .foregroundColor(.accentText)
        }
        .listRowBackground(Color.glassBackground)
    }
}

// MARK: - Supporting Views
struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.neonAqua)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.neonAqua)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsNavigationRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let destination: Destination
    
    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.neonAqua)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primaryText)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondaryText)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
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
                    VStack(spacing: 30) {
                        // Logo and Title
                        VStack(spacing: 16) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 80))
                                .foregroundColor(.neonAqua)
                                .shadow(color: .neonAqua.opacity(0.5), radius: 10)
                            
                            Text("Clean-Flow")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Version 1.0.0")
                                .font(.subheadline)
                                .foregroundColor(.accentText)
                        }
                        .padding(.top, 40)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 16) {
                            Text("About Clean-Flow")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            Text("Clean-Flow is a comprehensive hospital cleaning cycle management system designed to track, verify, and audit all cleaning protocols. With QR/NFC verification, real-time monitoring, and detailed audit logs, Clean-Flow ensures the highest standards of cleanliness and compliance in healthcare environments.")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .glassCard()
                        
                        // Features
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Key Features")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureRow(icon: "qrcode", title: "QR/NFC Scanning", description: "Verify cleaning areas with QR codes or NFC tags")
                                FeatureRow(icon: "chart.bar.fill", title: "Real-time Dashboard", description: "Monitor cleaning cycles and compliance rates")
                                FeatureRow(icon: "doc.text.magnifyingglass", title: "Audit System", description: "Comprehensive audit logs and reporting")
                                FeatureRow(icon: "person.2.fill", title: "Personnel Management", description: "Manage staff roles and permissions")
                            }
                        }
                        .padding()
                        .glassCard()
                        
                        // Copyright
                        VStack(spacing: 8) {
                            Text("© 2024 Clean-Flow")
                                .font(.caption)
                                .foregroundColor(.secondaryText)
                            
                            Text("All rights reserved")
                                .font(.caption2)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Help View
struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
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
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.neonAqua)
                            
                            Text("Help Center")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Find answers to common questions")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 40)
                        
                        // FAQ Sections
                        VStack(spacing: 16) {
                            FAQSection(
                                title: "Getting Started",
                                questions: [
                                    FAQ(question: "How do I sign in?", answer: "Use your hospital email and password to sign in to Clean-Flow."),
                                    FAQ(question: "What are QR codes?", answer: "QR codes are placed in hospital areas to verify cleaning protocols."),
                                    FAQ(question: "How do NFC tags work?", answer: "Hold your iPhone near NFC tags to automatically identify areas.")
                                ]
                            )
                            
                            FAQSection(
                                title: "Cleaning Protocols",
                                questions: [
                                    FAQ(question: "How do I start a cleaning protocol?", answer: "Scan a QR code or NFC tag, then select the appropriate protocol."),
                                    FAQ(question: "What if I miss a step?", answer: "You can add notes explaining why a step was missed."),
                                    FAQ(question: "How long do protocols take?", answer: "Each protocol has an estimated duration displayed on screen.")
                                ]
                            )
                            
                            FAQSection(
                                title: "Audits & Compliance",
                                questions: [
                                    FAQ(question: "How are audits conducted?", answer: "Auditors review completed cleaning runs and assign compliance scores."),
                                    FAQ(question: "What is a good compliance score?", answer: "Scores above 90% are considered excellent compliance."),
                                    FAQ(question: "How often are audits performed?", answer: "Audit frequency varies by area and hospital requirements.")
                                ]
                            )
                        }
                        
                        // Contact Support
                        VStack(spacing: 16) {
                            Text("Still Need Help?")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                            
                            Text("Contact our support team for personalized assistance")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            Button(action: {
                                // Contact support
                            }) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .font(.title2)
                                    
                                    Text("Contact Support")
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
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Help")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Supporting Views for Help
struct FAQSection: View {
    let title: String
    let questions: [FAQ]
    @State private var expandedQuestions = Set<String>()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                ForEach(questions) { faq in
                    VStack(spacing: 0) {
                        Button(action: {
                            if expandedQuestions.contains(faq.id) {
                                expandedQuestions.remove(faq.id)
                            } else {
                                expandedQuestions.insert(faq.id)
                            }
                        }) {
                            HStack {
                                Text(faq.question)
                                    .font(.subheadline)
                                    .foregroundColor(.primaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Image(systemName: expandedQuestions.contains(faq.id) ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                            }
                            .padding()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        if expandedQuestions.contains(faq.id) {
                            HStack {
                                Text(faq.answer)
                                    .font(.caption)
                                    .foregroundColor(.secondaryText)
                                    .multilineTextAlignment(.leading)
                                    .padding(.horizontal)
                                    .padding(.bottom)
                                
                                Spacer()
                            }
                        }
                    }
                    .background(Color.glassBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.glassBorder, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

struct FAQ: Identifiable {
    var id: String { question }
    let question: String
    let answer: String
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.neonAqua)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(AppState())
}
