import Foundation

struct CleaningProtocol: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    var category: String
    var estimatedTime: TimeInterval
    let steps: [Step]
    let requiredDuration: TimeInterval
    let areaType: AreaType
    let priority: Priority
    let isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    // Nested Step type for FirestoreRepository compatibility
    struct Step: Codable, Identifiable {
        let id: String
        let name: String
        let description: String
        let duration: TimeInterval
        let checklistItems: [ChecklistItem]

        // Computed property for backward compatibility
        var required: Bool { return true }
        var estimatedTime: TimeInterval { return duration }
        var chemicals: [String] { return [] }
        var equipment: [String] { return [] }
    }

    // Nested ChecklistItem type
    struct ChecklistItem: Codable, Identifiable {
        let id: String
        let text: String
        let isRequired: Bool
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

    // Initializer with defaults for backward compatibility
    init(id: String, name: String, description: String, category: String = "", estimatedTime: TimeInterval = 0, steps: [Step], requiredDuration: TimeInterval = 0, areaType: AreaType = .generalWard, priority: Priority = .medium, isActive: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.estimatedTime = estimatedTime
        self.steps = steps
        self.requiredDuration = requiredDuration
        self.areaType = areaType
        self.priority = priority
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// Legacy CleaningStep for backward compatibility with views
struct CleaningStep: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let required: Bool
    let estimatedTime: TimeInterval
    let checklistItems: [String]
    let chemicals: [String]
    let equipment: [String]
}

// Extension to convert between Step types
extension CleaningProtocol.Step {
    var asCleaningStep: CleaningStep {
        CleaningStep(
            id: id,
            name: name,
            description: description,
            required: required,
            estimatedTime: estimatedTime,
            checklistItems: checklistItems.map { $0.text },
            chemicals: chemicals,
            equipment: equipment
        )
    }
}

extension CleaningProtocol {
    var cleaningSteps: [CleaningStep] {
        steps.map { $0.asCleaningStep }
    }
}

extension CleaningProtocol {
    static var mock: CleaningProtocol {
        CleaningProtocol(
            id: "protocol-1",
            name: "OR Suite Protocol A",
            description: "Comprehensive cleaning protocol for operating rooms",
            category: "Operating Room",
            estimatedTime: 1800,
            steps: [
                Step(
                    id: "step-1",
                    name: "Surface Disinfection",
                    description: "Disinfect all horizontal surfaces",
                    duration: 600,
                    checklistItems: [
                        ChecklistItem(id: "item-1", text: "Wipe all surfaces", isRequired: true),
                        ChecklistItem(id: "item-2", text: "Apply disinfectant", isRequired: true),
                        ChecklistItem(id: "item-3", text: "Wait contact time", isRequired: true)
                    ]
                ),
                Step(
                    id: "step-2",
                    name: "Equipment Cleaning",
                    description: "Clean and disinfect medical equipment",
                    duration: 900,
                    checklistItems: [
                        ChecklistItem(id: "item-4", text: "Disconnect power", isRequired: true),
                        ChecklistItem(id: "item-5", text: "Clean surfaces", isRequired: true),
                        ChecklistItem(id: "item-6", text: "Verify cleanliness", isRequired: true)
                    ]
                )
            ],
            requiredDuration: 1800,
            areaType: .operatingRoom,
            priority: .critical,
            isActive: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
