import Foundation
import FirebaseFirestore
// import FirebaseFirestoreSwift // Will add later

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
        do {
            try db.collection("users").document(user.id).setData(from: user, merge: true) { error in
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
                let user = try self.decoder.decode(User.self, from: document.data())
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
                    let cleaningProtocol = try self.decoder.decode(CleaningProtocol.self, from: document.data())
                    protocols.append(cleaningProtocol)
                } catch {
                    print("🟥 Protocol Decoding Error for document \(document.documentID): \(error)")
                    decodingErrors.append(error)
                }
            }
            
            if protocols.isEmpty && !decodingErrors.isEmpty {
                completion(.failure(decodingErrors.first!))
            } else {
                completion(.success(protocols))
            }
        }
    }
    
    func saveProtocol(_ cleaningProtocol: CleaningProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            try db.collection("protocols").document(cleaningProtocol.id).setData(from: cleaningProtocol, merge: true) { error in
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
                    do {
                        let run = try self.decoder.decode(CleaningRun.self, from: document.data())
                print("🟡 Warning: Failed to decode \(decodingErrors.count) of today's cleaning runs out of \(snapshot?.documents.count ?? 0)")
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
                    let run = try self.decoder.decode(CleaningRun.self, from: document.data())
                    runs.append(run)
                } catch {
                    print("🟥 Real-time Cleaning Run Decoding Error for document \(document.documentID): \(error)")
                    decodingErrors.append(error)
                }
            }
            
            // If we have any decoding errors, log them but still return successfully decoded runs
            if !decodingErrors.isEmpty {
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
            
            do {
                let room = try self.decoder.decode(Room.self, from: data)
                completion(.success(room))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Dashboard Statistics
    func fetchDashboardStats(completion: @escaping (Result<DashboardStats, Error>) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
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
                    print("🟥 Dashboard Stats Cleaning Run Decoding Error for document \(document.documentID): \(error)")
                    decodingErrors.append(error)
                }
            }
            
            // If we have any decoding errors, log them but still return successfully decoded runs
            if !decodingErrors.isEmpty {
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
        // Mock calculation - in real app, this would check audit schedule
        let nextAuditDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return nextAuditDate.timeIntervalSince(Date())
    }
}

struct DashboardStats {
    let todayRuns: Int
    let completedRuns: Int
    let complianceRate: Double
    let averageTime: TimeInterval
    let nextAuditIn: TimeInterval
}
