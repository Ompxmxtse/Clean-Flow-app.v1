import Foundation

// MARK: - Equipment Model
// Aligned with React Native TypeScript interface for cross-platform compatibility

struct Equipment: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var description: String
    var location: String
    var qrCode: String
    var lastCleaned: Date?
    var cleaningIntervalHours: Int
    var category: EquipmentCategory
    var status: ComplianceStatus
    var assignedTo: String?
    var notes: String?
    var photoUrl: String?

    // Multi-tenant support
    var facilityId: String?
    var companyId: String?

    let createdAt: Date
    var updatedAt: Date

    enum EquipmentCategory: String, Codable, CaseIterable {
        case medicalDevice = "medical_device"
        case furniture = "furniture"
        case surface = "surface"
        case fixture = "fixture"
        case equipment = "equipment"
        case other = "other"

        var displayName: String {
            switch self {
            case .medicalDevice: return "Medical Device"
            case .furniture: return "Furniture"
            case .surface: return "Surface"
            case .fixture: return "Fixture"
            case .equipment: return "Equipment"
            case .other: return "Other"
            }
        }

        var icon: String {
            switch self {
            case .medicalDevice: return "cross.case.fill"
            case .furniture: return "bed.double.fill"
            case .surface: return "square.fill"
            case .fixture: return "light.max"
            case .equipment: return "gearshape.fill"
            case .other: return "tag.fill"
            }
        }
    }

    // Computed property for next cleaning due date
    var nextCleaningDue: Date? {
        guard let lastCleaned = lastCleaned else { return nil }
        return Calendar.current.date(byAdding: .hour, value: cleaningIntervalHours, to: lastCleaned)
    }

    // Computed property for hours until due
    var hoursUntilDue: Int? {
        guard let nextDue = nextCleaningDue else { return nil }
        let interval = nextDue.timeIntervalSince(Date())
        return Int(interval / 3600)
    }

    // Computed compliance status based on cleaning schedule
    var computedStatus: ComplianceStatus {
        guard let hoursUntil = hoursUntilDue else { return .overdue }

        if hoursUntil < 0 {
            return .overdue
        } else if hoursUntil < 4 {
            return .dueSoon
        } else {
            return .compliant
        }
    }

    init(id: String = UUID().uuidString,
         name: String,
         description: String = "",
         location: String,
         qrCode: String? = nil,
         lastCleaned: Date? = nil,
         cleaningIntervalHours: Int = 24,
         category: EquipmentCategory = .equipment,
         status: ComplianceStatus = .compliant,
         assignedTo: String? = nil,
         notes: String? = nil,
         photoUrl: String? = nil,
         facilityId: String? = nil,
         companyId: String? = nil,
         createdAt: Date = Date(),
         updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.location = location
        self.qrCode = qrCode ?? "CF-EQ-\(id)"
        self.lastCleaned = lastCleaned
        self.cleaningIntervalHours = cleaningIntervalHours
        self.category = category
        self.status = status
        self.assignedTo = assignedTo
        self.notes = notes
        self.photoUrl = photoUrl
        self.facilityId = facilityId
        self.companyId = companyId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Compliance Status
enum ComplianceStatus: String, Codable, CaseIterable {
    case compliant = "compliant"
    case dueSoon = "due_soon"
    case overdue = "overdue"

    var displayName: String {
        switch self {
        case .compliant: return "Compliant"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue"
        }
    }

    var color: String {
        switch self {
        case .compliant: return "10B981"  // Green
        case .dueSoon: return "F59E0B"    // Orange
        case .overdue: return "EF4444"    // Red
        }
    }
}

// MARK: - Cleaning Log Model
// Aligned with React Native CleaningLog interface

struct CleaningLog: Codable, Identifiable, Equatable {
    let id: String
    let equipmentId: String
    let equipmentName: String
    let userId: String
    let userName: String
    let cleaningType: CleaningType
    let completedAt: Date
    var notes: String?
    var photoUrls: [String]
    var duration: TimeInterval?
    var verified: Bool
    var verifiedBy: String?
    var verifiedAt: Date?

    // Multi-tenant support
    var facilityId: String?
    var companyId: String?

    enum CleaningType: String, Codable, CaseIterable {
        case routine = "routine"
        case deep = "deep"
        case terminal = "terminal"
        case spot = "spot"
        case emergency = "emergency"

        var displayName: String {
            switch self {
            case .routine: return "Routine Cleaning"
            case .deep: return "Deep Cleaning"
            case .terminal: return "Terminal Cleaning"
            case .spot: return "Spot Cleaning"
            case .emergency: return "Emergency Cleaning"
            }
        }

        var icon: String {
            switch self {
            case .routine: return "clock.fill"
            case .deep: return "sparkles"
            case .terminal: return "shield.checkered"
            case .spot: return "target"
            case .emergency: return "exclamationmark.triangle.fill"
            }
        }
    }

    init(id: String = UUID().uuidString,
         equipmentId: String,
         equipmentName: String,
         userId: String,
         userName: String,
         cleaningType: CleaningType = .routine,
         completedAt: Date = Date(),
         notes: String? = nil,
         photoUrls: [String] = [],
         duration: TimeInterval? = nil,
         verified: Bool = false,
         verifiedBy: String? = nil,
         verifiedAt: Date? = nil,
         facilityId: String? = nil,
         companyId: String? = nil) {
        self.id = id
        self.equipmentId = equipmentId
        self.equipmentName = equipmentName
        self.userId = userId
        self.userName = userName
        self.cleaningType = cleaningType
        self.completedAt = completedAt
        self.notes = notes
        self.photoUrls = photoUrls
        self.duration = duration
        self.verified = verified
        self.verifiedBy = verifiedBy
        self.verifiedAt = verifiedAt
        self.facilityId = facilityId
        self.companyId = companyId
    }
}

// MARK: - Mock Data
extension Equipment {
    static var mockData: [Equipment] {
        [
            Equipment(
                id: "eq-001",
                name: "Patient Monitor A",
                description: "Vital signs monitoring equipment",
                location: "ICU Room 101",
                lastCleaned: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
                cleaningIntervalHours: 8,
                category: .medicalDevice,
                status: .compliant
            ),
            Equipment(
                id: "eq-002",
                name: "Hospital Bed B",
                description: "Electric adjustable bed",
                location: "Ward 2B, Room 204",
                lastCleaned: Date().addingTimeInterval(-3600 * 20), // 20 hours ago
                cleaningIntervalHours: 24,
                category: .furniture,
                status: .dueSoon
            ),
            Equipment(
                id: "eq-003",
                name: "OR Table 1",
                description: "Surgical operating table",
                location: "Operating Room 1",
                lastCleaned: Date().addingTimeInterval(-3600 * 6), // 6 hours ago
                cleaningIntervalHours: 4,
                category: .medicalDevice,
                status: .overdue
            ),
            Equipment(
                id: "eq-004",
                name: "Examination Light",
                description: "LED surgical light fixture",
                location: "Operating Room 2",
                lastCleaned: Date().addingTimeInterval(-3600 * 1), // 1 hour ago
                cleaningIntervalHours: 12,
                category: .fixture,
                status: .compliant
            ),
            Equipment(
                id: "eq-005",
                name: "Nurse Station Counter",
                description: "Main nursing station work surface",
                location: "Ward 3A",
                lastCleaned: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
                cleaningIntervalHours: 8,
                category: .surface,
                status: .compliant
            )
        ]
    }

    static var mock: Equipment {
        mockData[0]
    }
}

extension CleaningLog {
    static var mockData: [CleaningLog] {
        [
            CleaningLog(
                id: "log-001",
                equipmentId: "eq-001",
                equipmentName: "Patient Monitor A",
                userId: "user-001",
                userName: "John Doe",
                cleaningType: .routine,
                completedAt: Date().addingTimeInterval(-3600 * 2),
                notes: "Standard disinfection completed",
                duration: 600
            ),
            CleaningLog(
                id: "log-002",
                equipmentId: "eq-003",
                equipmentName: "OR Table 1",
                userId: "user-002",
                userName: "Jane Smith",
                cleaningType: .terminal,
                completedAt: Date().addingTimeInterval(-3600 * 6),
                notes: "Post-surgery terminal cleaning",
                photoUrls: ["photo1.jpg"],
                duration: 1800,
                verified: true,
                verifiedBy: "Supervisor Mike"
            ),
            CleaningLog(
                id: "log-003",
                equipmentId: "eq-002",
                equipmentName: "Hospital Bed B",
                userId: "user-001",
                userName: "John Doe",
                cleaningType: .deep,
                completedAt: Date().addingTimeInterval(-3600 * 20),
                duration: 1200
            )
        ]
    }

    static var mock: CleaningLog {
        mockData[0]
    }
}
