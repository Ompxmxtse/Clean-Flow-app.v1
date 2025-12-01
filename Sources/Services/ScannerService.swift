import Foundation
import AVFoundation
import CoreNFC
import UserNotifications
import UIKit

class ScannerService: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var scanResult: ScanResult?
    @Published var errorMessage: String?
    
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
    
    // MARK: - NFC Scanner
    @available(iOS 13.0, *)
    func startNFCTagReading(completion: @escaping (Result<String, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(ScannerError.nfcNotAvailable))
            return
        }
        
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.begin()
        
        // Store completion handler for NFC delegate
        self.nfcCompletion = completion
    }
    
    private var nfcCompletion: ((Result<String, Error>) -> Void)?
    
    func validateNFCTag(_ tagData: String, completion: @escaping (Result<ScanResult, Error>) -> Void) {
        // Parse NFC tag data format
        let components = tagData.components(separatedBy: ":")
        guard components.count >= 2 else {
            completion(.failure(ScannerError.invalidNFCFormat))
            return
        }
        
        let areaId = components[0]
        let assetType = components[1]
        
        // Validate with Firestore
        validateNFCTagData(areaId: areaId, assetType: assetType) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let isValid):
                    if isValid {
                        let scanResult = ScanResult(
                            type: .nfc,
                            areaId: areaId,
                            protocolId: nil,
                            areaName: "Mock NFC Area \(areaId)",
                            protocolName: nil,
                            assetType: assetType,
                            timestamp: Date(),
                            isValid: true
                        )
                        self?.scanResult = scanResult
                        self?.triggerHapticFeedback()
                        completion(.success(scanResult))
                    } else {
                        completion(.failure(ScannerError.invalidNFCTag))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func validateAreaAndProtocol(areaId: String, protocolId: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // In real implementation, validate against Firestore
        // For now, simulate validation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(true)) // Mock success
        }
    }
    
    private func validateNFCTagData(areaId: String, assetType: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        // In real implementation, validate against Firestore
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(.success(true)) // Mock success
        }
    }
    
    private func triggerHapticFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Show notification
        let content = UNMutableNotificationContent()
        content.title = "Scan Successful"
        content.body = "Area verified successfully"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - NFC Session Delegate
@available(iOS 13.0, *)
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first else {
            nfcCompletion?(.failure(ScannerError.invalidNFCFormat))
            return
        }
        
        // For Text records, skip status byte and language code
        let payload = record.payload
        if record.typeNameFormat == .nfcWellKnown,
           let type = String(data: record.type, encoding: .utf8),
           type == "T",
           payload.count > 0 {
            let statusByte = payload[0]
            let languageCodeLength = Int(statusByte & 0x3F)
            let textStartIndex = 1 + languageCodeLength
            if payload.count > textStartIndex,
               let text = String(data: payload.suffix(from: textStartIndex), encoding: .utf8) {
                nfcCompletion?(.success(text))
                nfcCompletion = nil
                return
            }
        }
        
        // Fallback for other record types
        if let text = String(data: payload, encoding: .utf8) {
            nfcCompletion?(.success(text))
        } else {
            nfcCompletion?(.failure(ScannerError.invalidNFCFormat))
        }
        nfcCompletion = nil
    }
            return
        }
        
        nfcCompletion?(.success(payload))
        nfcCompletion = nil
    }
}

// MARK: - Models
struct ScanResult {
    let type: ScanType
    let areaId: String
    let protocolId: String?
    let areaName: String
    let protocolName: String?
    let assetType: String?
    let timestamp: Date
    let isValid: Bool
}

enum ScanType {
    case qr
    case nfc
}

enum ScannerError: LocalizedError {
    case cameraPermissionDenied
    case nfcNotAvailable
    case invalidQRFormat
    case invalidNFCFormat
    case invalidAreaOrProtocol
    case invalidNFCTag
    
    var errorDescription: String? {
        switch self {
        case .cameraPermissionDenied:
            return "Camera permission is required for QR scanning"
        case .nfcNotAvailable:
            return "NFC is not available on this device"
        case .invalidQRFormat:
            return "Invalid QR code format"
        case .invalidNFCFormat:
            return "Invalid NFC tag format"
        case .invalidAreaOrProtocol:
            return "Invalid area or protocol specified"
        case .invalidNFCTag:
            return "Invalid NFC tag data"
        }
    }
}
