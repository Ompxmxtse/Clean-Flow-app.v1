import Foundation

struct CleaningProtocol: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let steps: [CleaningStep]
    let requiredDuration: TimeInterval
    let areaType: AreaType
    let priority: Priority
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
    
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
}

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

extension CleaningProtocol {
    static var mock: CleaningProtocol {
        CleaningProtocol(
            id: "protocol-1",
            name: "OR Suite Protocol A",
            description: "Comprehensive cleaning protocol for operating rooms",
            steps: [
                CleaningStep(
                    id: "step-1",
                    name: "Surface Disinfection",
                    description: "Disinfect all horizontal surfaces",
                    required: true,
                    estimatedTime: 600,
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
                    checklistItems: ["Disconnect power", "Clean surfaces", "Verify cleanliness"],
                    chemicals: ["Medical grade disinfectant"],
                    equipment: ["Cleaning brushes", "PPE"]
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
