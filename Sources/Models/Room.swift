import Foundation

struct Room: Codable, Identifiable {
    let id: String
    let name: String
    let type: RoomType
    let floor: String
    let building: String
    let qrCode: String?
    let nfcTag: String?
    var lastCleaned: Date?
    var cleaningFrequency: TimeInterval
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

        init(from string: String) {
            self = RoomType(rawValue: string) ?? .generalWard
        }
    }

    init(id: String, name: String, type: RoomType, floor: String, building: String, qrCode: String? = nil, nfcTag: String? = nil, lastCleaned: Date? = nil, cleaningFrequency: TimeInterval = 86400, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.type = type
        self.floor = floor
        self.building = building
        self.qrCode = qrCode
        self.nfcTag = nfcTag
        self.lastCleaned = lastCleaned
        self.cleaningFrequency = cleaningFrequency
        self.isActive = isActive
        self.createdAt = createdAt
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
            lastCleaned: Date().addingTimeInterval(-3600),
            cleaningFrequency: 86400,
            isActive: true,
            createdAt: Date()
        )
    }
}
