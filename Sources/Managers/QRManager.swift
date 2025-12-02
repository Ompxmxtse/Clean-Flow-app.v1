import Foundation
import AVFoundation
import SwiftUI
import UIKit
import Combine

class QRManager: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var isScanning = false
    @Published var scannedCode: String?
    @Published var errorMessage: String?
    
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var completion: ((Result<String, Error>) -> Void)?
    
    func startScanning(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        
        // Check camera permission
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .denied, .restricted:
            completion(.failure(QRError.permissionDenied))
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCaptureSession()
                    } else {
                        completion(.failure(QRError.permissionDenied))
                    }
                }
            }
        @unknown default:
            completion(.failure(QRError.unknown))
        }
    }
    
    private func setupCaptureSession() {
        let session = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            completion?(.failure(QRError.cameraUnavailable))
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
            } else {
                completion?(.failure(QRError.cameraUnavailable))
                return
            }
        } catch {
            completion?(.failure(QRError.cameraUnavailable))
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            completion?(.failure(QRError.cameraUnavailable))
            return
        }
        
        captureSession = session
        
        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.isScanning = true
            }
        }
    }
    
    func stopScanning() {
        captureSession?.stopRunning()
        captureSession = nil
        previewLayer = nil
        isScanning = false
        scannedCode = nil
    }
    
    func getPreviewLayer() -> AVCaptureVideoPreviewLayer? {
        guard let captureSession = captureSession else { return nil }
        
        if previewLayer == nil {
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.frame = UIScreen.main.bounds
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.cornerRadius = 20
            previewLayer?.masksToBounds = true
        }
        
        return previewLayer
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else {
            return
        }
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        
        scannedCode = stringValue
        completion?(.success(stringValue))
        stopScanning()
    }
    
    func validateQRCode(_ code: String) -> QRValidationResult {
        // Expected format: CF-AREA-{areaId}-PROTOCOL-{protocolId}
        let pattern = #"^CF-AREA-(.+)-PROTOCOL-(.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: code, range: NSRange(code.startIndex..., in: code)),
              let areaRange = Range(match.range(at: 1), in: code),
              let protocolRange = Range(match.range(at: 2), in: code) else {
            return QRValidationResult(
                isValid: false,
                areaId: nil,
                protocolId: nil,
                error: "Invalid QR code format"
            )
        }
        
        let areaId = String(code[areaRange])
        let protocolId = String(code[protocolRange])
        
        return QRValidationResult(
            isValid: true,
            areaId: areaId,
            protocolId: protocolId,
            error: nil
        )
    }
    
    func parseQRCode(_ code: String) -> QRCodeData? {
        let validation = validateQRCode(code)
        guard validation.isValid else { return nil }
        
        return QRCodeData(
            rawCode: code,
            areaId: validation.areaId!,
            protocolId: validation.protocolId!,
            timestamp: Date()
        )
    }
}

// MARK: - Models
struct QRCodeData {
    let rawCode: String
    let areaId: String
    let protocolId: String
    let timestamp: Date
}

struct QRValidationResult {
    let isValid: Bool
    let areaId: String?
    let protocolId: String?
    let error: String?
}

enum QRError: LocalizedError {
    case permissionDenied
    case cameraUnavailable
    case invalidFormat
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera permission is required for QR scanning"
        case .cameraUnavailable:
            return "Camera is not available"
        case .invalidFormat:
            return "Invalid QR code format"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
