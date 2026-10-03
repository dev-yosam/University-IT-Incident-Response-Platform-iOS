import Foundation

nonisolated struct CampusLocation: Identifiable, Equatable, Sendable {
    let id: UUID
    let campus: String
    let building: String
    let room: String

    init(
        id: UUID = UUID(),
        campus: String,
        building: String,
        room: String
    ) throws {
        let campus = campus.trimmingCharacters(in: .whitespacesAndNewlines)
        let building = building.trimmingCharacters(in: .whitespacesAndNewlines)
        let room = room.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !campus.isEmpty else {
            throw IncidentValidationError.emptyCampus
        }
        guard !building.isEmpty else {
            throw IncidentValidationError.emptyBuilding
        }
        guard !room.isEmpty else {
            throw IncidentValidationError.emptyRoom
        }

        self.id = id
        self.campus = campus
        self.building = building
        self.room = room
    }
}
