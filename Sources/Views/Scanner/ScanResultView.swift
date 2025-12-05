import SwiftUI

struct ScanResultView: View {
    let result: ScanResult
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
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
                    VStack(spacing: 24) {
                        // Success Icon
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.successGreen)
                                .shadow(color: .successGreen.opacity(0.5), radius: 10)
                            
                            Text("Scan Successful")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                            
                            Text("Area verified successfully")
                                .font(.subheadline)
                                .foregroundColor(.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Scan Details
                        VStack(spacing: 16) {
                            Text("Scan Details")
                                .font(.headline)
                                .foregroundColor(.primaryText)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            VStack(spacing: 12) {
                                ScanDetailRow(
                                    title: "Scan Type",
                                    value: result.type == .qr ? "QR Code" : "NFC Tag",
                                    icon: result.type == .qr ? "qrcode" : "antenna.radiowaves.left.and.right"
                                )
                                
                                ScanDetailRow(
                                    title: "Area ID",
                                    value: result.areaId,
                                    icon: "location"
                                )
                                
                                ScanDetailRow(
                                    title: "Area Name",
                                    value: result.areaName,
                                    icon: "building.2"
                                )
                                
                                if let protocolId = result.protocolId, let protocolName = result.protocolName {
                                    ScanDetailRow(
                                        title: "Protocol ID",
                                        value: protocolId,
                                        icon: "list.bullet.clipboard"
                                    )
                                    
                                    ScanDetailRow(
                                        title: "Protocol Name",
                                        value: protocolName,
                                        icon: "doc.text"
                                    )
                                }
                                
                                ScanDetailRow(
                                    title: "Scan Time",
                                    value: formatTime(result.timestamp),
                                    icon: "clock"
                                )
                            }
                        }
                        .padding()
                        .glassCard()
                        
                        // Action Buttons
                        VStack(spacing: 16) {
                            if result.protocolId != nil && result.protocolName != nil {
                                Button(action: {
                                    startCleaningProtocol()
                                }) {
                                    HStack {
                                        Image(systemName: "play.circle.fill")
                                            .font(.title2)
                                        
                                        Text("Start Cleaning Protocol")
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
                            }
                            
                            Button(action: {
                                dismiss()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left.circle")
                                        .font(.title2)
                                    
                                    Text("Back to Scanner")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.glassBackground)
                                .foregroundColor(.primaryText)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.glassBorder, lineWidth: 1)
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.accentText)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func startCleaningProtocol() {
        guard let protocolId = result.protocolId,
              let protocolName = result.protocolName else { return }
        
        // Find the protocol in app state
        if let cleaningProtocol = appState.protocols.first(where: { $0.id == protocolId }) {
            appState.startCleaningProtocol(cleaningProtocol, areaId: result.areaId, areaName: result.areaName)
            dismiss()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

fileprivate struct ScanDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.neonAqua)
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
        .padding(.vertical, 8)
    }
}

#Preview {
    ScanResultView(
        result: ScanResult(
            type: .qr,
            areaId: "AREA-123",
            protocolId: "PROTOCOL-456",
            areaName: "Operating Room 1",
            protocolName: "OR Suite Protocol A",
            timestamp: Date(),
            isValid: true
        )
    )
    .environmentObject(AppState())
}
