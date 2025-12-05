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
            "email": user.email,
            "name": user.name,
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

            guard let document = document, document.exists, let data = document.data() else {
                completion(.success(nil))
                return
            }

            let user = User(
                id: data["id"] as? String ?? "",
                email: data["email"] as? String ?? "",
                name: data["name"] as? String ?? "",
                role: User.UserRole(rawValue: data["role"] as? String ?? "") ?? .cleaner,
                department: data["department"] as? String ?? "",
                isActive: data["isActive"] as? Bool ?? true,
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                lastLogin: (data["lastLogin"] as? Timestamp)?.dateValue() ?? Date()
            )
            completion(.success(user))
        }
    }

    // Alias for AuthService compatibility
    func fetchUser(id: String, completion: @escaping (Result<User?, Error>) -> Void) {
        getUser(id: id, completion: completion)
    }

    // MARK: - Protocol Operations
    func getProtocols(completion: @escaping (Result<[CleaningProtocol], Error>) -> Void) {
        db.collection("protocols").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            var protocols: [CleaningProtocol] = []

            snapshot?.documents.forEach { document in
                let data = document.data()
                let stepsData = data["steps"] as? [[String: Any]] ?? []
                let steps = stepsData.compactMap { stepData -> CleaningStep? in
                    guard let id = stepData["id"] as? String,
                          let name = stepData["name"] as? String else {
                        return nil
                    }
                    let checklistItems = (stepData["checklistItems"] as? [String]) ?? []
                    return CleaningStep(
                        id: id,
                        name: name,
                        description: stepData["description"] as? String ?? "",
                        required: stepData["required"] as? Bool ?? true,
                        estimatedTime: stepData["estimatedTime"] as? TimeInterval ?? 0,
                        duration: stepData["duration"] as? TimeInterval ?? 0,
                        checklistItems: checklistItems,
                        chemicals: stepData["chemicals"] as? [String] ?? [],
                        equipment: stepData["equipment"] as? [String] ?? []
                    )
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
            }

            completion(.success(protocols))
        }
    }

    // Alias for AppState compatibility
    func fetchProtocols(completion: @escaping (Result<[CleaningProtocol], Error>) -> Void) {
        getProtocols(completion: completion)
    }

    func saveProtocol(_ cleaningProtocol: CleaningProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        let stepsData = cleaningProtocol.steps.map { step in
            return [
                "id": step.id,
                "name": step.name,
                "description": step.description,
                "required": step.required,
                "estimatedTime": step.estimatedTime,
                "duration": step.duration,
                "checklistItems": step.checklistItems,
                "chemicals": step.chemicals,
                "equipment": step.equipment
            ] as [String: Any]
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

                snapshot?.documents.forEach { document in
                    let data = document.data()
                    let steps = (data["steps"] as? [[String: Any]] ?? []).compactMap { stepData -> CompletedStep? in
                        guard let id = stepData["id"] as? String,
                              let stepId = stepData["stepId"] as? String,
                              let name = stepData["name"] as? String else {
                            return nil
                        }
                        let checklistItems = (stepData["checklistItems"] as? [[String: Any]] ?? []).compactMap { itemData -> CompletedChecklistItem? in
                            guard let id = itemData["id"] as? String else {
                                return nil
                            }
                            let itemDict = itemData["item"] as? [String: Any]
                            let text = itemDict?["text"] as? String ?? ""
                            let isRequired = itemDict?["isRequired"] as? Bool ?? false
                            return CompletedChecklistItem(
                                id: id,
                                item: ChecklistItem(id: UUID().uuidString, text: text, isRequired: isRequired),
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

    // Alias for AppState compatibility
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
                        return CompletedStep(
                            id: id,
                            stepId: stepId,
                            name: name,
                            completed: stepData["completed"] as? Bool ?? false,
                            completedAt: (stepData["completedAt"] as? Timestamp)?.dateValue(),
                            completedBy: stepData["completedBy"] as? String,
                            notes: stepData["notes"] as? String,
                            checklistItems: []
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
        var query: Query = db.collection("cleaningRuns")
            .order(by: "startTime", descending: true)
            .limit(to: 100)

        if let userId = userId {
            query = query.whereField("cleanerId", isEqualTo: userId)
        }

        return query.addSnapshotListener { snapshot, error in
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
                    return CompletedStep(
                        id: id,
                        stepId: stepId,
                        name: name,
                        completed: stepData["completed"] as? Bool ?? false,
                        completedAt: (stepData["completedAt"] as? Timestamp)?.dateValue(),
                        completedBy: stepData["completedBy"] as? String,
                        notes: stepData["notes"] as? String,
                        checklistItems: []
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

    // MARK: - Room Operations
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

            let typeString = data["type"] as? String ?? ""
            let roomType = Room.RoomType(rawValue: typeString) ?? .generalWard

            let room = Room(
                id: snapshot?.documentID ?? "",
                name: data["name"] as? String ?? "",
                type: roomType,
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

        db.collection("cleaningRuns")
            .whereField("startTime", isGreaterThanOrEqualTo: today)
            .whereField("startTime", isLessThan: tomorrow)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                let runCount = snapshot?.documents.count ?? 0
                let completedCount = snapshot?.documents.filter { doc in
                    let status = doc.data()["status"] as? String ?? ""
                    return status == "completed" || status == "verified"
                }.count ?? 0

                var totalCompliance: Double = 0
                snapshot?.documents.forEach { doc in
                    if let score = doc.data()["complianceScore"] as? Double {
                        totalCompliance += score
                    }
                }

                let stats = DashboardStats(
                    todayRuns: runCount,
                    completedRuns: completedCount,
                    complianceRate: runCount > 0 ? totalCompliance / Double(runCount) : 0,
                    averageTime: self?.calculateAverageTime() ?? 1800,
                    nextAuditIn: self?.calculateNextAuditIn() ?? 86400
                )

                completion(.success(stats))
            }
    }

    private func calculateAverageTime() -> TimeInterval {
        return 1800 // 30 minutes placeholder
    }

    private func calculateNextAuditIn() -> TimeInterval {
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
