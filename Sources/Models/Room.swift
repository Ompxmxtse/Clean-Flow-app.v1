import Foundation

struct Room: Codable, Identifiable {
    let id: String
    let name: String
    let type: RoomType
    let floor: String
    let building: String
    let qrCode: String?
    let nfcTag: String?
    let isActive: Bool
    let createdAt: Date
    
    enum RoomType: String, Codable, CaseIterable {
        case operatingRoom = "operating_room"
        case patientRoom = "patient_room"
        case icu = "icu"
        case emergency = "emergency"
        case laboratory = "laboratory"
        case generalWard = "general_ward"
        case isolation = "isolation"
        case recovery = "recovery"
    }
}

extension Room {
    static var mock: Room {
        Room(
            id: "room-1",
            name: "Operating Room 1",
            type: .operatingRoom,
            floor: "2",
            building: "Main Hospital",
            qrCode: "CF-AREA-room-1-PROTOCOL-protocol-1",
            nfcTag: "room-1:operating_room",
            isActive: true,
            createdAt: Date()
        )
    }
}
