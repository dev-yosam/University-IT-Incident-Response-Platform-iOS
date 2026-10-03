import Foundation

nonisolated protocol CampusLocationRepository: Sendable {
    func fetchLocations() async throws -> [CampusLocation]
    func fetchLocation(id: UUID) async throws -> CampusLocation
}
