import Foundation
import AVFoundation
import CoreNFC
import UserNotifications
import UIKit
import Combine

class ScannerService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scanResult: ScanResult?
    @Published var errorMessage: String?

    static let shared = ScannerService()

    // Private properties for capture session
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var qrCompletion: ((Result<String, ScannerError>) -> Void)?
    private var nfcCompletion: ((Result<String, ScannerError>) -> Void)?
    private var lastScanResult: ScanResult?
    
    // MARK: - QR Scanner
    func startQRScanner(completion: @escaping (Result<String, Error>) -> Void) {
        guard AVCaptureDevice.authorizationStatus(for: .video) == .authorized else {
            completion(.failure(ScannerError.cameraPermissionDenied))
            return
        }
        
        isScanning = true
        
        // In a real implementation, this would set up AVCaptureSession
        // For now, we'll simulate a QR scan
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isScanning = false
            // Mock QR code data
            let mockQRData = "CF-AREA-123-PROTOCOL-456"
            completion(.success(mockQRData))
        }
    }
    
    func validateQRCode(_ qrData: String, completion: @escaping (Result<ScanResult, Error>) -> Void) {
        // Parse QR data format: CF-AREA-{areaId}-PROTOCOL-{protocolId}
        let components = qrData.components(separatedBy: "-")
        guard components.count >= 5,
              components[0] == "CF",
              components[1] == "AREA",
              components[3] == "PROTOCOL" else {
            completion(.failure(ScannerError.invalidQRFormat))
            return
        }
        
        let areaId = components[2]
        let protocolId = components[4]
        
        // Validate with Firestore
        validateAreaAndProtocol(areaId: areaId, protocolId: protocolId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isValid):
                    if isValid {
                        let scanResult = ScanResult(
                            type: .qr,
                            areaId: areaId,
                            protocolId: protocolId,
                            areaName: "Mock Area \(areaId)",
                            protocolName: "Mock Protocol \(protocolId)",
                            assetType: nil,
                            timestamp: Date(),
                            isValid: true
                        )
                        self?.scanResult = scanResult
                        self?.triggerHapticFeedback()
                        completion(.success(scanResult))
                    } else {
                        completion(.failure(ScannerError.invalidAreaOrProtocol))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Validation Helper
    private func validateAreaAndProtocol(areaId: String, protocolId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // Validate area and protocol exist in the system
        // In production, this would query Firestore to verify the IDs
        // For now, we'll accept any non-empty IDs as valid
        guard !areaId.isEmpty, !protocolId.isEmpty else {
            completion(.success(false))
            return
        }
        // Simulate async validation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(true))
        }
    }

    // MARK: - Haptic Feedback
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - NFC Scanner
    @available(iOS 13.0, *)
    func startNFCScanning(completion: @escaping (Result<ScanResult, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(ScannerError.nfcUnavailable))
            return
        }
        // Store completion for NFC delegate callback
        // NFC scanning is initiated asynchronously
    }
    
    func stopQRScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        isScanning = false
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            qrCompletion?(.failure(.cameraUnavailable))
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            if session.canAddInput(input) {
                session.addInput(input)
                
                let output = AVCaptureMetadataOutput()
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                if session.canAddOutput(output) {
                    session.addOutput(output)
                    output.metadataObjectTypes = [.qr]
                    
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.videoGravity = .resizeAspectFill
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.captureSession = session
                        self?.previewLayer = previewLayer
                        self?.isScanning = true
                        
                        session.startRunning()
                    }
                } else {
                    qrCompletion?(.failure(.scanningFailed))
                }
            } else {
                qrCompletion?(.failure(.scanningFailed))
            }
        } catch {
            qrCompletion?(.failure(.scanningFailed))
        }
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        return previewLayer
    }
    
    // MARK: - NFC Scanning
    func startNFScanning(completion: @escaping (Result<String, ScannerError>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(.nfcUnavailable))
            return
        }
        
        nfcCompletion = completion
        
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session.begin()
    }
    
    // MARK: - Parse QR Code
    func parseQRCode(_ string: String) -> ScanResult? {
        guard string.hasPrefix("cleanflow://") else { return nil }
        
        let components = string.dropFirst(12).components(separatedBy: "&")
        var areaId: String?
        var protocolId: String?
        var areaName: String?
        
        for component in components {
            let pair = component.components(separatedBy: "=")
            guard pair.count == 2 else { continue }
            
            switch pair[0] {
            case "area":
                areaId = pair[1]
            case "protocol":
                protocolId = pair[1]
            case "name":
                areaName = pair[1].removingPercentEncoding
            default:
                break
            }
        }
        
        guard let id = areaId, let name = areaName else { return nil }
        
        return ScanResult(
            type: .qr,
            areaId: id,
            protocolId: protocolId,
            areaName: name
        )
    }
}

// MARK: - AVCaptureMetadataOutputObjectsDelegate
extension ScannerService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let stringValue = metadataObject.stringValue else {
            return
        }
        
        if let scanResult = parseQRCode(stringValue) {
            lastScanResult = scanResult
            qrCompletion?(.success(stringValue))
        } else {
            qrCompletion?(.failure(.invalidQRFormat))
        }
        
        qrCompletion = nil
    }
}

// MARK: - NFCNDEFReaderSessionDelegate
extension ScannerService: NFCNDEFReaderSessionDelegate {
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first,
              let payload = String(data: record.payload, encoding: .utf8) else {
            nfcCompletion?(.failure(.invalidNFCFormat))
            return
        }
        
        if let scanResult = parseQRCode(payload) {
            lastScanResult = scanResult
            nfcCompletion?(.success(payload))
        } else {
            nfcCompletion?(.failure(.invalidNFCFormat))
        }
        nfcCompletion = nil
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        nfcCompletion?(.failure(.nfcError(error)))
        nfcCompletion = nil
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session became active
    }
}

// MARK: - Models
struct ScanResult {
    let type: ScanType
    let areaId: String
    let protocolId: String?
    let areaName: String
    var protocolName: String?
    var assetType: String?
    var timestamp: Date
    var isValid: Bool

    init(type: ScanType, areaId: String, protocolId: String?, areaName: String, protocolName: String? = nil, assetType: String? = nil, timestamp: Date = Date(), isValid: Bool = true) {
        self.type = type
        self.areaId = areaId
        self.protocolId = protocolId
        self.areaName = areaName
        self.protocolName = protocolName
        self.assetType = assetType
        self.timestamp = timestamp
        self.isValid = isValid
    }
}

enum ScanType {
    case qr
    case nfc
}

enum ScannerError: LocalizedError {
    case cameraUnavailable
    case cameraPermissionDenied
    case nfcUnavailable
    case scanningFailed
    case invalidQRFormat
    case invalidNFCFormat
    case invalidAreaOrProtocol
    case nfcError(Error)

    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return "Camera is not available on this device"
        case .cameraPermissionDenied:
            return "Camera permission was denied. Please enable camera access in Settings."
        case .nfcUnavailable:
            return "NFC is not available on this device"
        case .scanningFailed:
            return "Failed to start scanning"
        case .invalidQRFormat:
            return "Invalid QR code format"
        case .invalidNFCFormat:
            return "Invalid NFC tag format"
        case .invalidAreaOrProtocol:
            return "Invalid area or protocol ID"
        case .nfcError(let error):
            return "NFC error: \(error.localizedDescription)"
        }
    }
}
