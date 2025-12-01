import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var scannerService = ScannerService.shared
    @State private var isShowingResult = false
    @State private var lastScanResult: ScanResult?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreview(scannerService: scannerService)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text("Scan QR Code")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: toggleFlash) {
                        Image(systemName: "flashlight.on.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Scanning Frame
                VStack(spacing: 20) {
                    Text("Align QR code within frame")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    
                    // Scanning Frame Visual
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(red: 43/255, green: 203/255, blue: 255/255), lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            VStack {
                                HStack {
                                    Rectangle()
                                        .fill(Color(red: 43/255, green: 203/255, blue: 255/255))
                                        .frame(width: 20, height: 3)
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(red: 43/255, green: 203/255, blue: 255/255))
                                        .frame(width: 20, height: 3)
                                }
                                Spacer()
                                HStack {
                                    Rectangle()
                                        .fill(Color(red: 43/255, green: 203/255, blue: 255/255))
                                        .frame(width: 20, height: 3)
                                    Spacer()
                                    Rectangle()
                                        .fill(Color(red: 43/255, green: 203/255, blue: 255/255))
                                        .frame(width: 20, height: 3)
                                }
                            }
                        )
                    
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundColor(.white)
                        .opacity(scannerService.isScanning ? 1.0 : 0.6)
                }
                
                Spacer()
                
                // Bottom Instructions
                VStack(spacing: 16) {
                    Button(action: scanManually) {
                        Text("Enter Code Manually")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 43/255, green: 203/255, blue: 255/255))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Text("Make sure the QR code is well lit and clearly visible")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .onAppear {
            startScanning()
        }
        .onDisappear {
            scannerService.stopQRScanning()
        }
        .onChange(of: scannerService.lastScanResult) { result in
            if let result = result {
                lastScanResult = result
                scannerService.stopQRScanning()
                isShowingResult = true
            }
        }
        .sheet(isPresented: $isShowingResult) {
            if let result = lastScanResult {
                ScanResultView(result: result)
                    .environmentObject(AppState())
            }
        }
    }
    
    private func startScanning() {
        scannerService.startQRScanning { result in
            switch result {
            case .success:
                // Handle successful scan
                break
            case .failure(let error):
                print("Scanning error: \(error)")
                    VStack(spacing: 8) {
                        Image(systemName: mode.icon)
                            .font(.title2)
                            .foregroundColor(scanMode == mode ? .deepNavy : .neonAqua)
                        
                        Text(mode.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(scanMode == mode ? .deepNavy : .primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(scanMode == mode ? Color.neonAqua : Color.glassBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonAqua, lineWidth: scanMode == mode ? 0 : 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Scanner Content
    @ViewBuilder
    private var scannerContent: some View {
        switch scanMode {
        case .qr:
            QRScannerView(qrManager: qrManager) { result in
                handleQRResult(result)
            }
        case .nfc:
            NFCScannerView(nfcManager: nfcManager) { result in
                handleNFCResult(result)
            }
        }
    }
    
    // MARK: - Instructions Section
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Instructions")
                .font(.headline)
                .foregroundColor(.primaryText)
            
            VStack(alignment: .leading, spacing: 8) {
                if scanMode == .qr {
                    InstructionRow(
                        icon: "qrcode",
                        text: "Position QR code within the frame",
                        color: .neonAqua
                    )
                    InstructionRow(
                        icon: "hand.tap",
                        text: "Hold steady for automatic detection",
                        color: .successGreen
                    )
                    InstructionRow(
                        icon: "checkmark.circle",
                        text: "Verify area and protocol information",
                        color: .warningYellow
                    )
                } else {
                    InstructionRow(
                        icon: "antenna.radiowaves.left.and.right",
                        text: "Hold iPhone near NFC tag",
                        color: .neonAqua
                    )
                    InstructionRow(
                        icon: "touchid",
                        text: "Keep phone close until detection",
                        color: .successGreen
                    )
                    InstructionRow(
                        icon: "checkmark.circle",
                        text: "Confirm area information",
                        color: .warningYellow
                    )
                }
            }
        }
        .padding()
        .glassCard()
    }
    
    // MARK: - Helper Methods
    private func stopCurrentScan() {
        qrManager.stopScanning()
        if #available(iOS 13.0, *) {
            nfcManager.stopScanning()
        }
    }
    
    private func handleQRResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let qrData):
            let validation = qrManager.validateQRCode(qrData)
            if validation.isValid {
                guard let areaId = validation.areaId,
                      let protocolId = validation.protocolId else {
                    qrManager.errorMessage = "Invalid scan data"
                    return
                }
                let scanResult = ScanResult(
                    type: .qr,
                    areaId: areaId,
                    protocolId: protocolId,
                    areaName: "Area \(areaId)",
                    protocolName: "Protocol \(protocolId)",
                    timestamp: Date(),
                    isValid: true
                )
                self.scanResult = scanResult
                self.showingResult = true
                
                // Trigger haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            } else {
                qrManager.errorMessage = validation.error ?? "Invalid QR code"
            }
        case .failure(let error):
            qrManager.errorMessage = error.localizedDescription
        }
    }
    
    private func handleNFCResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let tagData):
            if #available(iOS 13.0, *) {
                let validation = nfcManager.validateNFCTag(tagData)
                if validation.isValid {
                    guard let areaId = validation.areaId else {
                        nfcManager.errorMessage = "Invalid scan data"
                        return
                    }
                    let scanResult = ScanResult(
                        type: .nfc,
                        areaId: areaId,
                        protocolId: nil,
                        areaName: "Area \(areaId)",
                        protocolName: nil,
                        timestamp: Date(),
                        isValid: true
                    )
                    self.scanResult = scanResult
                    self.showingResult = true
                    
                    // Trigger haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                } else {
                    nfcManager.errorMessage = validation.error ?? "Invalid NFC tag"
                }
            }
        case .failure(let error):
            nfcManager.errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Supporting Views
struct QRScannerView: UIViewRepresentable {
    let qrManager: QRManager
    let onResult: (Result<String, Error>) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        
        // Create scanner view
        let scannerView = QRScannerUIView(qrManager: qrManager, onResult: onResult)
        scannerView.frame = view.bounds
        scannerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(scannerView)
class QRScannerUIView: UIView {
    private let qrManager: QRManager
    private let onResult: (Result<String, Error>) -> Void
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var overlayView: UIView?
    
    init(qrManager: QRManager, onResult: @escaping (Result<String, Error>) -> Void) {
        self.qrManager = qrManager
        self.onResult = onResult
        super.init(frame: .zero)
        setupScanner()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        qrManager.stopScanning()
    }
        self.qrManager = qrManager
        self.onResult = onResult
        super.init(frame: .zero)
        setupScanner()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupScanner() {
        qrManager.startScanning { [weak self] result in
            DispatchQueue.main.async {
                self?.onResult(result)
            }
        }
        
        setupPreviewLayer()
        setupOverlay()
    }
    
    private func setupPreviewLayer() {
        guard let previewLayer = qrManager.getPreviewLayer() else { return }
        
        previewLayer.frame = bounds
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
    }
    
    private func setupOverlay() {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        // Create scanning frame
        let frameSize: CGFloat = 250
        let frameView = UIView()
        frameView.frame = CGRect(
            x: (bounds.width - frameSize) / 2,
            y: (bounds.height - frameSize) / 2,
            width: frameSize,
            height: frameSize
        )
        frameView.layer.borderColor = UIColor.systemCyan.cgColor
        frameView.layer.borderWidth = 3
        frameView.layer.cornerRadius = 20
        frameView.backgroundColor = UIColor.clear
        
        // Add corner markers
        addCornerMarkers(to: frameView)
        
        overlay.addSubview(frameView)
        overlay.frame = bounds
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addSubview(overlay)
        overlayView = overlay
    }
    
    private func addCornerMarkers(to view: UIView) {
        let cornerLength: CGFloat = 30
        let cornerWidth: CGFloat = 4
        let cornerColor = UIColor.systemCyan
        
        // Top-left corner
        let topLeft = UIView()
        topLeft.frame = CGRect(x: 0, y: 0, width: cornerLength, height: cornerWidth)
        topLeft.backgroundColor = cornerColor
        view.addSubview(topLeft)
        
        let topLeftVertical = UIView()
        topLeftVertical.frame = CGRect(x: 0, y: 0, width: cornerWidth, height: cornerLength)
        topLeftVertical.backgroundColor = cornerColor
        view.addSubview(topLeftVertical)
        
        // Top-right corner
        let topRight = UIView()
        topRight.frame = CGRect(x: view.frame.width - cornerLength, y: 0, width: cornerLength, height: cornerWidth)
        topRight.backgroundColor = cornerColor
        view.addSubview(topRight)
        
        let topRightVertical = UIView()
        topRightVertical.frame = CGRect(x: view.frame.width - cornerWidth, y: 0, width: cornerWidth, height: cornerLength)
        topRightVertical.backgroundColor = cornerColor
        view.addSubview(topRightVertical)
        
        // Bottom-left corner
        let bottomLeft = UIView()
        bottomLeft.frame = CGRect(x: 0, y: view.frame.height - cornerWidth, width: cornerLength, height: cornerWidth)
        bottomLeft.backgroundColor = cornerColor
        view.addSubview(bottomLeft)
        
        let bottomLeftVertical = UIView()
        bottomLeftVertical.frame = CGRect(x: 0, y: view.frame.height - cornerLength, width: cornerWidth, height: cornerLength)
        bottomLeftVertical.backgroundColor = cornerColor
        view.addSubview(bottomLeftVertical)
        
        // Bottom-right corner
        let bottomRight = UIView()
        bottomRight.frame = CGRect(x: view.frame.width - cornerLength, y: view.frame.height - cornerWidth, width: cornerLength, height: cornerWidth)
        bottomRight.backgroundColor = cornerColor
        view.addSubview(bottomRight)
        
        let bottomRightVertical = UIView()
        bottomRightVertical.frame = CGRect(x: view.frame.width - cornerWidth, y: view.frame.height - cornerLength, width: cornerWidth, height: cornerLength)
        bottomRightVertical.backgroundColor = cornerColor
        view.addSubview(bottomRightVertical)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = bounds
        overlayView?.frame = bounds
    }
}

@available(iOS 13.0, *)
struct NFCScannerView: View {
    let nfcManager: NFCManager
    let onResult: (Result<String, Error>) -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            // NFC Animation
            VStack(spacing: 20) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 100))
                    .foregroundColor(.neonAqua)
                    .scaleEffect(nfcManager.isScanning ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: nfcManager.isScanning)
                
                Text("Ready to Scan")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primaryText)
            }
            
            // Scan Button
            Button(action: {
                nfcManager.startScanning { result in
                    DispatchQueue.main.async {
                        onResult(result)
                    }
                }
            }) {
                HStack {
                    Image(systemName: "nfc")
                        .font(.title2)
                    
                    Text(nfcManager.isScanning ? "Scanning..." : "Start NFC Scan")
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
            .disabled(nfcManager.isScanning)
        }
        .padding()
        .glassCard()
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primaryText)
            
            Spacer()
        }
    }
}

#Preview {
    ScannerView()
        .environmentObject(AppState())
        .environmentObject(AuthService())
}
