import Foundation
import CoreNFC
import UIKit

@available(iOS 13.0, *)
class NFCManager: NSObject, ObservableObject, NFCNDEFReaderSessionDelegate {
    @Published var isScanning = false
    @Published var scannedTag: String?
    @Published var errorMessage: String?
    
    private var completion: ((Result<String, Error>) -> Void)?
    
    func startScanning(completion: @escaping (Result<String, Error>) -> Void) {
        self.completion = completion
        
        guard NFCNDEFReaderSession.readingAvailable else {
            completion(.failure(NFCError.notAvailable))
            return
        }
        
        let session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone near the NFC tag to read it"
        session?.begin()
        
        isScanning = true
    }
    
    func stopScanning() {
        isScanning = false
        scannedTag = nil
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.isScanning = false
            self.completion?(.failure(error))
            self.completion = nil
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        guard let message = messages.first,
              let record = message.records.first else {
            DispatchQueue.main.async {
                self.completion?(.failure(NFCError.invalidTag))
            }
            return
        }
        
        // Parse the NFC tag data
        let payloadData = record.payload
        let payloadString = String(data: payloadData, encoding: .utf8) ?? ""
        
        DispatchQueue.main.async {
            self.scannedTag = payloadString
            self.completion?(.success(payloadString))
            self.isScanning = false
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        // Session became active
    }
    
    // MARK: - NFC Tag Validation
    func validateNFCTag(_ tagData: String) -> NFCValidationResult {
        // Expected format: {areaId}:{assetType}:{timestamp}
        let components = tagData.components(separatedBy: ":")
        
        guard components.count >= 2 else {
            return NFCValidationResult(
                isValid: false,
                areaId: nil,
                assetType: nil,
                error: "Invalid NFC tag format"
            )
        }
        
        let areaId = components[0]
        let assetType = components[1]
        
        return NFCValidationResult(
            isValid: true,
            areaId: areaId,
            assetType: assetType,
            error: nil
        )
    }
    
    func parseNFCTag(_ tagData: String) -> NFCTagData? {
        let validation = validateNFCTag(tagData)
        guard validation.isValid else { return nil }
        
        return NFCTagData(
            rawData: tagData,
            areaId: validation.areaId!,
            assetType: validation.assetType!,
            timestamp: Date()
        )
    }
    
    // MARK: - Mock NFC Writing (for testing)
    func mockNFCTagWrite(areaId: String, assetType: String) -> String {
        return "\(areaId):\(assetType):\(Date().timeIntervalSince1970)"
    }
}

// MARK: - Models
struct NFCTagData {
    let rawData: String
    let areaId: String
    let assetType: String
    let timestamp: Date
}

struct NFCValidationResult {
    let isValid: Bool
    let areaId: String?
    let assetType: String?
    let error: String?
}

enum NFCError: LocalizedError {
    case notAvailable
    case invalidTag
    case readFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "NFC is not available on this device"
        case .invalidTag:
            return "Invalid NFC tag format"
        case .readFailed:
            return "Failed to read NFC tag"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
