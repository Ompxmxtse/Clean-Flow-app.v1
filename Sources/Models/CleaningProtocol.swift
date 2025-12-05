import Foundation

struct CleaningProtocol: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let category: String
    let estimatedTime: TimeInterval
    let steps: [CleaningStep]
    let isActive: Bool
    let createdAt: Date
    var updatedAt: Date?
    var priority: Priority?
    var areaType: AreaType?

    // Nested types for backwards compatibility with FirestoreRepository
    struct Step: Codable, Identifiable {
        let id: String
        let name: String
        let description: String
        let duration: TimeInterval
        let checklistItems: [ChecklistItem]

        struct ChecklistItem: Codable, Identifiable {
            let id: String
            let text: String
            let isRequired: Bool
        }
    }

    enum AreaType: String, Codable, CaseIterable {
        case operatingRoom = "operating_room"
        case patientRoom = "patient_room"
        case icu = "icu"
        case emergency = "emergency"
        case laboratory = "laboratory"
        case generalWard = "general_ward"
    }

    enum Priority: String, Codable, CaseIterable {
        case critical = "critical"
        case high = "high"
        case medium = "medium"
        case low = "low"
    }

    init(id: String, name: String, description: String, category: String = "", estimatedTime: TimeInterval = 0, steps: [CleaningStep] = [], isActive: Bool = true, createdAt: Date = Date(), updatedAt: Date? = nil, priority: Priority? = nil, areaType: AreaType? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.estimatedTime = estimatedTime
        self.steps = steps
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.priority = priority
        self.areaType = areaType
    }
}

struct CleaningStep: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let required: Bool
    let estimatedTime: TimeInterval
    let duration: TimeInterval
    let checklistItems: [String]
    let chemicals: [String]
    let equipment: [String]

    init(id: String, name: String, description: String = "", required: Bool = true, estimatedTime: TimeInterval = 0, duration: TimeInterval = 0, checklistItems: [String] = [], chemicals: [String] = [], equipment: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.required = required
        self.estimatedTime = estimatedTime
        self.duration = duration > 0 ? duration : estimatedTime
        self.checklistItems = checklistItems
        self.chemicals = chemicals
        self.equipment = equipment
    }
}

extension CleaningProtocol {
    // Computed property alias for views that use requiredDuration
    var requiredDuration: TimeInterval { estimatedTime }

    static var mock: CleaningProtocol {
        CleaningProtocol(
            id: "protocol-1",
            name: "OR Suite Protocol A",
            description: "Comprehensive cleaning protocol for operating rooms",
            category: "Operating Room",
            estimatedTime: 1800,
            steps: [
                CleaningStep(
                    id: "step-1",
                    name: "Surface Disinfection",
                    description: "Disinfect all horizontal surfaces",
                    required: true,
                    estimatedTime: 600,
                    duration: 600,
                    checklistItems: ["Wipe all surfaces", "Apply disinfectant", "Wait contact time"],
                    chemicals: ["Bleach solution", "Alcohol wipes"],
                    equipment: ["Microfiber cloths", "Spray bottles"]
                ),
                CleaningStep(
                    id: "step-2",
                    name: "Equipment Cleaning",
                    description: "Clean and disinfect medical equipment",
                    required: true,
                    estimatedTime: 900,
                    duration: 900,
                    checklistItems: ["Disconnect power", "Clean surfaces", "Verify cleanliness"],
                    chemicals: ["Medical grade disinfectant"],
                    equipment: ["Cleaning brushes", "PPE"]
                )
            ],
            isActive: true,
            createdAt: Date(),
            updatedAt: Date(),
            priority: .critical,
            areaType: .operatingRoom
        )
    }
}
