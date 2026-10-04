import Foundation

nonisolated struct GetCampusLocations: Sendable {
    private let repository: any CampusLocationRepository

    init(repository: any CampusLocationRepository) {
        self.repository = repository
    }

    func execute() async throws(Failure) -> [CampusLocation] {
        let locations: [CampusLocation]
        do {
            locations = try await repository.fetchLocations()
        } catch {
            throw .couldNotLoadLocations
        }
        guard !locations.isEmpty else { throw .noLocationsAvailable }
        return locations
    }

    enum Failure: LocalizedError, Equatable {
        case couldNotLoadLocations
        case noLocationsAvailable

        var errorDescription: String? {
            switch self {
            case .couldNotLoadLocations:
                return "Campus locations could not be loaded. Try loading them again."
            case .noLocationsAvailable:
                return "No campus locations are available for reporting. Try loading them again."
            }
        }
    }
}
