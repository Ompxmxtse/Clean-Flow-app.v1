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
                // Scanning error - Log in production
                print("Scanning error: \(error)")
            }
        }
    }
    
    private func toggleFlash() {
        // Toggle flash functionality
    }
    
    private func scanManually() {
        // Manual scan functionality
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
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update preview
    }
}

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
    
    private func setupScanner() {
        // Get the preview layer from QRManager
        guard let previewLayer = qrManager.getPreviewLayer() else {
            onResult(.failure(NSError(domain: "QRScanner", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to setup camera preview"])))
            return
        }
        
        // Configure preview layer
        previewLayer.frame = self.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        self.layer.addSublayer(previewLayer)
        self.previewLayer = previewLayer
        
        // Start scanning
        qrManager.startScanning { [weak self] result in
            DispatchQueue.main.async {
                self?.onResult(result)
            }
        }
        
        // Add tap gesture for focus (optional)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: self)
        // Focus functionality could be added here if needed
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer?.frame = self.layer.bounds
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
