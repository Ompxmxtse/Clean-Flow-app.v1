import Foundation
import FirebaseFirestore

class FirestoreRepository {
    static let shared = FirestoreRepository()
    private let db = Firestore.firestore()
    private let encoder: Firestore.Encoder
    private let decoder: Firestore.Decoder
    
    private init() {
        encoder = Firestore.Encoder()
        decoder = Firestore.Decoder()
    }
    
    // MARK: - User Operations
    func saveUser(_ user: User, completion: @escaping (Result<Void, Error>) -> Void) {
        let data: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "role": user.role.rawValue,
            "department": user.department,
            "isActive": user.isActive,
            "createdAt": user.createdAt,
            "lastLogin": user.lastLogin
        ]
        
        db.collection("users").document(user.id).setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getUser(id: String, completion: @escaping (Result<User?, Error>) -> Void) {
        db.collection("users").document(id).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.success(nil))
                return
            }
            
            do {
                let data = document.data()
                let user = User(
                    id: data["id"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    role: User.UserRole(rawValue: data["role"] as? String ?? "") ?? .cleaner,
                    department: data["department"] as? String ?? "",
                    isActive: data["isActive"] as? Bool ?? true,
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    lastLogin: (data["lastLogin"] as? Timestamp)?.dateValue() ?? Date()
                )
                completion(.success(user))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Protocol Operations
    func getProtocols(completion: @escaping (Result<[CleaningProtocol], Error>) -> Void) {
        db.collection("protocols").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var protocols: [CleaningProtocol] = []
            var decodingErrors: [Error] = []
            
            snapshot?.documents.forEach { document in
                do {
                    let data = document.data()
                    let stepsData = data["steps"] as? [[String: Any]] ?? []
                    let steps = stepsData.compactMap { stepData -> CleaningProtocol.Step? in
                        guard let id = stepData["id"] as? String,
                              let name = stepData["name"] as? String else {
                            return nil
                        }
                        let checklistItems = (stepData["checklistItems"] as? [[String: Any]] ?? []).compactMap { itemData -> CleaningProtocol.ChecklistItem? in
                            guard let id = itemData["id"] as? String,
                                  let text = itemData["text"] as? String else {
                                return nil
                            }
                            return CleaningProtocol.ChecklistItem(id: id, text: text, isRequired: itemData["isRequired"] as? Bool ?? false)
                        }
                        return CleaningProtocol.Step(id: id, name: name, description: stepData["description"] as? String ?? "", duration: stepData["duration"] as? TimeInterval ?? 0, checklistItems: checklistItems)
                    }
                    
                    let cleaningProtocol = CleaningProtocol(
                        id: document.documentID,
                        name: data["name"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        category: data["category"] as? String ?? "",
                        estimatedTime: data["estimatedTime"] as? TimeInterval ?? 0,
                        steps: steps,
                        isActive: data["isActive"] as? Bool ?? true,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    protocols.append(cleaningProtocol)
                } catch {
                    // Protocol Decoding Error - Log in production
                    print("🟥 Protocol Decoding Error for document \(document.documentID): \(error)")
                    decodingErrors.append(error)
                }
            }
            
            if protocols.isEmpty && !decodingErrors.isEmpty {
                if let firstError = decodingErrors.first {
                    completion(.failure(firstError))
                } else {
                    completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown decoding error"])))
                }
                return
            } else {
                completion(.success(protocols))
            }
        }
    }
    
    func saveProtocol(_ cleaningProtocol: CleaningProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        let stepsData = cleaningProtocol.steps.map { step in
            return [
                "id": step.id,
                "name": step.name,
                "description": step.description,
                "duration": step.duration,
                "checklistItems": step.checklistItems.map { item in
                    return [
                        "id": item.id,
                        "text": item.text,
                        "isRequired": item.isRequired
                    ]
                }
            ]
        }
        
        let data: [String: Any] = [
            "id": cleaningProtocol.id,
            "name": cleaningProtocol.name,
            "description": cleaningProtocol.description,
            "category": cleaningProtocol.category,
            "estimatedTime": cleaningProtocol.estimatedTime,
            "steps": stepsData,
            "isActive": cleaningProtocol.isActive,
            "createdAt": cleaningProtocol.createdAt
        ]
        
        db.collection("protocols").document(cleaningProtocol.id).setData(data, merge: true) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Cleaning Run Operations
    func saveCleaningRun(_ run: CleaningRun, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("cleaningRuns").document(run.id).setData(from: run, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func getRecentRuns(limit: Int = 10, completion: @escaping (Result<[CleaningRun], Error>) -> Void) {
        db.collection("cleaningRuns")
            .order(by: "startTime", descending: true)
            .limit(to: limit)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                var runs: [CleaningRun] = []
                var decodingErrors: [Error] = []
                
                snapshot?.documents.forEach { document in
                    do {
                        let data = document.data()
                        let steps = (data["steps"] as? [[String: Any]] ?? []).compactMap { stepData -> CompletedStep? in
                            guard let id = stepData["id"] as? String,
                                  let stepId = stepData["stepId"] as? String,
                                  let name = stepData["name"] as? String else {
                                return nil
                            }
                            let checklistItems = (stepData["checklistItems"] as? [[String: Any]] ?? []).compactMap { itemData -> CompletedChecklistItem? in
                                guard let id = itemData["id"] as? String,
                                      let itemData = itemData["item"] as? [String: Any],
                                      let text = itemData["text"] as? String else {
                                    return nil
                                }
                                return CompletedChecklistItem(
                                    id: id,
                                    item: ChecklistItem(id: UUID().uuidString, text: text, isRequired: itemData["isRequired"] as? Bool ?? false),
                                    completed: itemData["completed"] as? Bool ?? false,
                                    completedAt: (itemData["completedAt"] as? Timestamp)?.dateValue()
                                )
                            }
                            
                            return CompletedStep(
                                id: id,
                                stepId: stepId,
                                name: name,
                                completed: stepData["completed"] as? Bool ?? false,
                                completedAt: (stepData["completedAt"] as? Timestamp)?.dateValue(),
                                completedBy: stepData["completedBy"] as? String,
                                notes: stepData["notes"] as? String,
                                checklistItems: checklistItems
                            )
                        }
                        
                        let run = CleaningRun(
                            id: document.documentID,
                            protocolId: data["protocolId"] as? String ?? "",
                            protocolName: data["protocolName"] as? String ?? "",
                            cleanerId: data["cleanerId"] as? String ?? "",
                            cleanerName: data["cleanerName"] as? String ?? "",
                            areaId: data["areaId"] as? String ?? "",
                            areaName: data["areaName"] as? String ?? "",
                            startTime: (data["startTime"] as? Timestamp)?.dateValue() ?? Date(),
                            endTime: (data["endTime"] as? Timestamp)?.dateValue(),
                            status: CleaningStatus(rawValue: data["status"] as? String ?? "") ?? .pending,
                            verificationMethod: VerificationMethod(rawValue: data["verificationMethod"] as? String ?? "") ?? .manual,
                            qrCode: data["qrCode"] as? String,
                            nfcTag: data["nfcTag"] as? String,
                            steps: steps,
                            notes: data["notes"] as? String,
                            auditorId: data["auditorId"] as? String,
                            auditorName: data["auditorName"] as? String,
                            complianceScore: data["complianceScore"] as? Double,
                            createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                        runs.append(run)
                    } catch {
                        // Warning: Failed to decode documents - Log in production
                        decodingErrors.append(error)
                        print("🟡 Warning: Failed to decode \(decodingErrors.count) of today's cleaning runs out of \(snapshot?.documents.count ?? 0)")
                    }
                }
                
                completion(.success(runs))
            }
        }
    }
    
    // MARK: - Convenience Methods (for AppState compatibility)
    func fetchProtocols(completion: @escaping (Result<[CleaningProtocol], Error>) -> Void) {
        getProtocols(completion: completion)
    }

    func fetchCleaningRunsToday(completion: @escaping (Result<[CleaningRun], Error>) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])))
            return
        }

        db.collection("cleaningRuns")
            .whereField("startTime", isGreaterThanOrEqualTo: today)
            .whereField("startTime", isLessThan: tomorrow)
            .order(by: "startTime", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var runs: [CleaningRun] = []

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    let steps = (data["steps"] as? [[String: Any]] ?? []).compactMap { stepData -> CompletedStep? in
                        guard let id = stepData["id"] as? String,
                              let stepId = stepData["stepId"] as? String,
                              let name = stepData["name"] as? String else {
                            return nil
                        }
                        let checklistItems = (stepData["checklistItems"] as? [[String: Any]] ?? []).compactMap { itemData -> CompletedChecklistItem? in
                            guard let id = itemData["id"] as? String,
                                  let itemDict = itemData["item"] as? [String: Any],
                                  let text = itemDict["text"] as? String else {
                                return nil
                            }
                            return CompletedChecklistItem(
                                id: id,
                                item: ChecklistItem(id: UUID().uuidString, text: text, isRequired: itemDict["isRequired"] as? Bool ?? false),
                                completed: itemData["completed"] as? Bool ?? false,
                                completedAt: (itemData["completedAt"] as? Timestamp)?.dateValue()
                            )
                        }

                        return CompletedStep(
                            id: id,
                            stepId: stepId,
                            name: name,
                            completed: stepData["completed"] as? Bool ?? false,
                            completedAt: (stepData["completedAt"] as? Timestamp)?.dateValue(),
                            completedBy: stepData["completedBy"] as? String,
                            notes: stepData["notes"] as? String,
                            checklistItems: checklistItems
                        )
                    }

                    let run = CleaningRun(
                        id: document.documentID,
                        protocolId: data["protocolId"] as? String ?? "",
                        protocolName: data["protocolName"] as? String ?? "",
                        cleanerId: data["cleanerId"] as? String ?? "",
                        cleanerName: data["cleanerName"] as? String ?? "",
                        areaId: data["areaId"] as? String ?? "",
                        areaName: data["areaName"] as? String ?? "",
                        startTime: (data["startTime"] as? Timestamp)?.dateValue() ?? Date(),
                        endTime: (data["endTime"] as? Timestamp)?.dateValue(),
                        status: CleaningStatus(rawValue: data["status"] as? String ?? "") ?? .pending,
                        verificationMethod: VerificationMethod(rawValue: data["verificationMethod"] as? String ?? "") ?? .manual,
                        qrCode: data["qrCode"] as? String,
                        nfcTag: data["nfcTag"] as? String,
                        steps: steps,
                        notes: data["notes"] as? String,
                        auditorId: data["auditorId"] as? String,
                        auditorName: data["auditorName"] as? String,
                        complianceScore: data["complianceScore"] as? Double,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    runs.append(run)
                }

                completion(.success(runs))
            }
    }

    // MARK: - Real-time Listener
    func listenToCleaningRuns(for userId: String? = nil, completion: @escaping (Result<[CleaningRun], Error>) -> Void) -> ListenerRegistration {
        var query: Query = db.collection("runs")
            .order(by: "completedAt", descending: true)
            .limit(to: 100)
        
        if let userId = userId {
            query = query.whereField("userId", isEqualTo: userId)
        }
        
        return query.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var runs: [CleaningRun] = []
            var decodingErrors: [Error] = []
            
            snapshot?.documents.forEach { document in
                do {
                    let data = document.data()
                    let steps = (data["steps"] as? [[String: Any]] ?? []).compactMap { stepData -> CompletedStep? in
                        guard let id = stepData["id"] as? String,
                              let stepId = stepData["stepId"] as? String,
                              let name = stepData["name"] as? String else {
                            return nil
                        }
                        let checklistItems = (stepData["checklistItems"] as? [[String: Any]] ?? []).compactMap { itemData -> CompletedChecklistItem? in
                            guard let id = itemData["id"] as? String,
                                  let itemData = itemData["item"] as? [String: Any],
                                  let text = itemData["text"] as? String else {
                                return nil
                            }
                            return CompletedChecklistItem(
                                id: id,
                                item: ChecklistItem(id: UUID().uuidString, text: text, isRequired: itemData["isRequired"] as? Bool ?? false),
                                completed: itemData["completed"] as? Bool ?? false,
                                completedAt: (itemData["completedAt"] as? Timestamp)?.dateValue()
                            )
                        }
                        
                        return CompletedStep(
                            id: id,
                            stepId: stepId,
                            name: name,
                            completed: stepData["completed"] as? Bool ?? false,
                            completedAt: (stepData["completedAt"] as? Timestamp)?.dateValue(),
                            completedBy: stepData["completedBy"] as? String,
                            notes: stepData["notes"] as? String,
                            checklistItems: checklistItems
                        )
                    }
                    
                    let run = CleaningRun(
                        id: document.documentID,
                        protocolId: data["protocolId"] as? String ?? "",
                        protocolName: data["protocolName"] as? String ?? "",
                        cleanerId: data["cleanerId"] as? String ?? "",
                        cleanerName: data["cleanerName"] as? String ?? "",
                        areaId: data["areaId"] as? String ?? "",
                        areaName: data["areaName"] as? String ?? "",
                        startTime: (data["startTime"] as? Timestamp)?.dateValue() ?? Date(),
                        endTime: (data["endTime"] as? Timestamp)?.dateValue(),
                        status: CleaningStatus(rawValue: data["status"] as? String ?? "") ?? .pending,
                        verificationMethod: VerificationMethod(rawValue: data["verificationMethod"] as? String ?? "") ?? .manual,
                        qrCode: data["qrCode"] as? String,
                        nfcTag: data["nfcTag"] as? String,
                        steps: steps,
                        notes: data["notes"] as? String,
                        auditorId: data["auditorId"] as? String,
                        auditorName: data["auditorName"] as? String,
                        complianceScore: data["complianceScore"] as? Double,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                    runs.append(run)
                } catch {
                    // Real-time Cleaning Run Decoding Error - Log in production
                    print("🟥 Real-time Cleaning Run Decoding Error for document \(document.documentID): \(error)")
                    decodingErrors.append(error)
                }
            }
            
            // If we have any decoding errors, log them but still return successfully decoded runs
            if !decodingErrors.isEmpty {
                // Warning: Failed to decode real-time cleaning runs - Log in production
                print("🟡 Warning: Failed to decode \(decodingErrors.count) real-time cleaning runs out of \(snapshot?.documents.count ?? 0)")
            }
            
            completion(.success(runs))
        }
    }
    
    // MARK: - Room Operations (for UI compatibility)
    func fetchRoom(roomId: String, completion: @escaping (Result<Room, Error>) -> Void) {
        db.collection("rooms").document(roomId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "Room not found"])))
                return
            }
            
            let room = Room(
                id: snapshot?.documentID ?? "",
                name: data["name"] as? String ?? "",
                type: data["type"] as? String ?? "",
                floor: data["floor"] as? String ?? "",
                building: data["building"] as? String ?? "",
                qrCode: data["qrCode"] as? String,
                nfcTag: data["nfcTag"] as? String,
                lastCleaned: (data["lastCleaned"] as? Timestamp)?.dateValue(),
                cleaningFrequency: data["cleaningFrequency"] as? TimeInterval ?? 86400,
                isActive: data["isActive"] as? Bool ?? true,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
            )
            
            completion(.success(room))
        }
    }
    
    // MARK: - Dashboard Statistics
    func fetchDashboardStats(completion: @escaping (Result<DashboardStats, Error>) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            completion(.failure(NSError(domain: "FirestoreError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to calculate date range"])))
            return
        }
        
        db.collection("runs")
            .whereField("completedAt", isGreaterThanOrEqualTo: today)
            .whereField("completedAt", isLessThan: tomorrow)
            .getDocuments { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var runs: [CleaningRun] = []
            var decodingErrors: [Error] = []
            
            snapshot?.documents.forEach { document in
                do {
                    let run = try self?.decoder.decode(CleaningRun.self, from: document.data())
                    if let run = run {
                        runs.append(run)
                    }
                } catch {
                    // Dashboard Stats Cleaning Run Decoding Error - Log in production
                    print("🟥 Dashboard Stats Cleaning Run Decoding Error for document \(document.documentID): \(error)")
                    decodingErrors.append(error)
                }
            }
            
            // If we have any decoding errors, log them but still return successfully decoded runs
            if !decodingErrors.isEmpty {
                // Warning: Failed to decode dashboard stats cleaning runs - Log in production
                print("🟡 Warning: Failed to decode \(decodingErrors.count) dashboard stats cleaning runs out of \(snapshot?.documents.count ?? 0)")
            }
            
            let stats = DashboardStats(
                todayRuns: runs.count,
                completedRuns: runs.count, // All runs in this collection are completed
                complianceRate: self?.calculateComplianceRate(runs: runs) ?? 0,
                averageTime: self?.calculateAverageTime(runs: runs) ?? 0,
                nextAuditIn: self?.calculateNextAuditIn() ?? 0
            )
            
            completion(.success(stats))
        }
    }
    
    private func calculateComplianceRate(runs: [CleaningRun]) -> Double {
        guard !runs.isEmpty else { return 0 }
        let totalCompliance = runs.reduce(0) { sum, run in
            sum + (run.complianceScore ?? 0)
        }
        return totalCompliance / Double(runs.count)
    }
    
    private func calculateAverageTime(runs: [CleaningRun]) -> TimeInterval {
        // For the new schema, we'd need to calculate this from protocol data
        // For now, return a placeholder
        return 1800 // 30 minutes
    }
    
    private func calculateNextAuditIn() -> TimeInterval {
        // Return next audit in 24 hours for now
        return 24 * 60 * 60 // 24 hours
    }
}

struct DashboardStats {
    let todayRuns: Int
    let completedRuns: Int
    let complianceRate: Double
    let averageTime: TimeInterval
    let nextAuditIn: TimeInterval
}
