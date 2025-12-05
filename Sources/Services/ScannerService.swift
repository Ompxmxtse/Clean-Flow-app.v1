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
    @Published var lastScanResult: ScanResult?

    static let shared = ScannerService()

    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var qrCompletion: ((Result<String, ScannerError>) -> Void)?
    private var nfcCompletion: ((Result<String, ScannerError>) -> Void)?

    // MARK: - QR Scanner
    func startQRScanner(completion: @escaping (Result<String, Error>) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            setupCaptureSession()
            self.qrCompletion = { result in
                switch result {
                case .success(let value):
                    completion(.success(value))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.setupCaptureSession()
                    self?.qrCompletion = { result in
                        switch result {
                        case .success(let value):
                            completion(.success(value))
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                } else {
                    completion(.failure(ScannerError.cameraPermissionDenied))
                }
            }
        default:
            completion(.failure(ScannerError.cameraPermissionDenied))
        }
    }

    func startQRScanning(completion: @escaping (Result<String, ScannerError>) -> Void) {
        qrCompletion = completion
        setupCaptureSession()
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
                case .success(let validationResult):
                    let scanResult = ScanResult(
                        type: .qr,
                        areaId: areaId,
                        protocolId: protocolId,
                        areaName: validationResult.areaName,
                        protocolName: validationResult.protocolName,
                        assetType: nil,
                        timestamp: Date(),
                        isValid: validationResult.isValid
                    )
                    self?.scanResult = scanResult
                    self?.lastScanResult = scanResult
                    self?.triggerHapticFeedback()
                    completion(.success(scanResult))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    private func validateAreaAndProtocol(areaId: String, protocolId: String, completion: @escaping (Result<ValidationResult, Error>) -> Void) {
        // Fetch room and protocol from Firestore to validate
        FirestoreRepository.shared.fetchRoom(roomId: areaId) { roomResult in
            switch roomResult {
            case .success(let room):
                FirestoreRepository.shared.getProtocols { protocolResult in
                    switch protocolResult {
                    case .success(let protocols):
                        if let matchingProtocol = protocols.first(where: { $0.id == protocolId }) {
                            completion(.success(ValidationResult(
                                isValid: true,
                                areaName: room.name,
                                protocolName: matchingProtocol.name
                            )))
                        } else {
                            completion(.success(ValidationResult(
                                isValid: false,
                                areaName: room.name,
                                protocolName: "Unknown Protocol"
                            )))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func triggerHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    // MARK: - NFC Scanner
    @available(iOS 13.0, *)
    func startNFCScanning(completion: @escaping (Result<ScanResult, Error>) -> Void) {
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(ScannerError.nfcUnavailable))
            return
        }

        nfcCompletion = { [weak self] result in
            switch result {
            case .success(let data):
                if let scanResult = self?.parseNFCData(data) {
                    completion(.success(scanResult))
                } else {
                    completion(.failure(ScannerError.invalidNFCFormat))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }

        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session.begin()
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

                    let layer = AVCaptureVideoPreviewLayer(session: session)
                    layer.videoGravity = .resizeAspectFill

                    DispatchQueue.main.async { [weak self] in
                        self?.captureSession = session
                        self?.previewLayer = layer
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
        // Handle cleanflow:// URL format
        if string.hasPrefix("cleanflow://") {
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
                areaName: name,
                protocolName: nil,
                assetType: nil,
                timestamp: Date(),
                isValid: true
            )
        }

        // Handle CF-AREA-{areaId}-PROTOCOL-{protocolId} format
        let components = string.components(separatedBy: "-")
        guard components.count >= 5,
              components[0] == "CF",
              components[1] == "AREA",
              components[3] == "PROTOCOL" else {
            return nil
        }

        return ScanResult(
            type: .qr,
            areaId: components[2],
            protocolId: components[4],
            areaName: "Area \(components[2])",
            protocolName: "Protocol \(components[4])",
            assetType: nil,
            timestamp: Date(),
            isValid: true
        )
    }

    private func parseNFCData(_ data: String) -> ScanResult? {
        // NFC format: {areaId}:{assetType}
        let components = data.components(separatedBy: ":")
        guard components.count >= 2 else { return nil }

        return ScanResult(
            type: .nfc,
            areaId: components[0],
            protocolId: nil,
            areaName: "Area \(components[0])",
            protocolName: nil,
            assetType: components[1],
            timestamp: Date(),
            isValid: true
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

        if let scanResult = parseNFCData(payload) {
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
struct ScanResult: Equatable {
    let type: ScanType
    let areaId: String
    let protocolId: String?
    let areaName: String
    var protocolName: String?
    var assetType: String?
    var timestamp: Date?
    var isValid: Bool

    init(type: ScanType, areaId: String, protocolId: String? = nil, areaName: String, protocolName: String? = nil, assetType: String? = nil, timestamp: Date? = nil, isValid: Bool = true) {
        self.type = type
        self.areaId = areaId
        self.protocolId = protocolId
        self.areaName = areaName
        self.protocolName = protocolName
        self.assetType = assetType
        self.timestamp = timestamp
        self.isValid = isValid
    }

    static func == (lhs: ScanResult, rhs: ScanResult) -> Bool {
        return lhs.areaId == rhs.areaId && lhs.protocolId == rhs.protocolId && lhs.type == rhs.type
    }
}

struct ValidationResult {
    let isValid: Bool
    let areaName: String
    let protocolName: String
}

enum ScanType: Equatable {
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
            return "Camera permission was denied"
        case .nfcUnavailable:
            return "NFC is not available on this device"
        case .scanningFailed:
            return "Failed to start scanning"
        case .invalidQRFormat:
            return "Invalid QR code format"
        case .invalidNFCFormat:
            return "Invalid NFC tag format"
        case .invalidAreaOrProtocol:
            return "Invalid area or protocol"
        case .nfcError(let error):
            return "NFC error: \(error.localizedDescription)"
        }
    }

    static func == (lhs: ScannerError, rhs: ScannerError) -> Bool {
        return lhs.errorDescription == rhs.errorDescription
    }
}
