import SwiftUI

struct ProtocolDetailView: View {
    let cleaningProtocol: CleaningProtocol
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedArea = ""
    @State private var showingStartConfirmation = false
    
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
                        headerSection
                        
                        // Protocol Info
                        protocolInfoSection
                        
                        // Steps Overview
                        stepsOverviewSection
                        
                        // Area Selection
                        areaSelectionSection
                        
                        // Start Button
                        startButtonSection
                    }
                    .padding()
                }
            }
            .navigationTitle(cleaningProtocol.name)
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
        .alert("Start Protocol", isPresented: $showingStartConfirmation) {
            Button("Start") {
                startProtocol()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you ready to start the \(cleaningProtocol.name) in \(selectedArea)?")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(cleaningProtocol.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
                .multilineTextAlignment(.center)
            
            Text(cleaningProtocol.description)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            
            HStack {
                priorityBadge
                Spacer()
                areaTypeBadge
            }
        }
        .padding(.top, 20)
    }
    
    // MARK: - Protocol Info Section
    private var protocolInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protocol Details")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                InfoRow(
                    icon: "clock",
                    title: "Estimated Duration",
                    value: formatDuration(cleaningProtocol.requiredDuration)
                )
                
                InfoRow(
                    icon: "list.bullet",
                    title: "Total Steps",
                    value: "\(cleaningProtocol.steps.count)"
                )
                
                InfoRow(
                    icon: "calendar",
                    title: "Last Updated",
                    value: formatDate(cleaningProtocol.updatedAt)
                )
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Steps Overview Section
    private var stepsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Steps Overview")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 12) {
                ForEach(Array(cleaningProtocol.steps.enumerated()), id: \.element.id) { index, step in
                    StepOverviewRow(
                        stepNumber: index + 1,
                        step: step
                    )
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Area Selection Section
    private var areaSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Area")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(spacing: 8) {
                Text("Choose the area where you'll perform this cleaning protocol")
                    .font(.subheadline)
                    .foregroundColor(.secondaryText)
                
                Menu {
                    ForEach(mockAreas, id: \.id) { area in
                        Button(area.name) {
                            selectedArea = area.name
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedArea.isEmpty ? "Select an area" : selectedArea)
                            .foregroundColor(selectedArea.isEmpty ? .secondaryText : .primaryText)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.secondaryText)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.glassBorder, lineWidth: 1)
                            )
                    )
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Start Button Section
    private var startButtonSection: some View {
        Button(action: {
            if !selectedArea.isEmpty {
                showingStartConfirmation = true
            }
        }) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                
                Text("Start Protocol")
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
            .clipShape(Capsule())
    }
    
    private var areaTypeBadge: some View {
        Text(cleaningProtocol.areaType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.neonAqua.opacity(0.2))
            .foregroundColor(.neonAqua)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch cleaningProtocol.priority {
        case .critical: return .errorRed
        case .high: return .warningYellow
        case .medium: return .neonAqua
        case .low: return .secondaryText
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func startProtocol() {
        appState.startCleaningProtocol(cleaningProtocol, areaId: "area-123", areaName: selectedArea)
        dismiss()
    }
    
    // Mock data
    private let mockAreas = [
        Area(id: "area-1", name: "Operating Room 1"),
        Area(id: "area-2", name: "Operating Room 2"),
        Area(id: "area-3", name: "ICU Room A"),
        Area(id: "area-4", name: "ICU Room B"),
        Area(id: "area-5", name: "Emergency Bay 1"),
        Area(id: "area-6", name: "Patient Room 101"),
        Area(id: "area-7", name: "Patient Room 102"),
        Area(id: "area-8", name: "Laboratory 1")
    ]
}

// MARK: - Supporting Views
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentText)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StepOverviewRow: View {
    let stepNumber: Int
    let step: CleaningStep
    
    var body: some View {
        HStack(spacing: 12) {
            // Step Number
            Text("\(stepNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.deepNavy)
                .frame(width: 30, height: 30)
                .background(Color.neonAqua)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(step.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primaryText)
                
                Text(step.description)
                    .font(.caption)
                    .foregroundColor(.secondaryText)
                    .lineLimit(2)
                
                HStack {
                    Text("\(formatDuration(step.estimatedTime))")
                        .font(.caption2)
                        .foregroundColor(.accentText)
                    
                    if step.required {
                        Text("• Required")
                            .font(.caption2)
                            .foregroundColor(.errorRed)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}

struct Area {
    let id: String
    let name: String
}

#Preview {
    ProtocolDetailView(protocol: .mock)
        .environmentObject(AppState())
}
