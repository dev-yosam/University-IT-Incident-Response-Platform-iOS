import Foundation

actor MockCampusLocationRepository: CampusLocationRepository {
    private let locations: [CampusLocation]
    private let error: RepositoryError?

    init(locations: [CampusLocation] = [], error: RepositoryError? = nil) {
        self.locations = locations
        self.error = error
    }

    func fetchLocations() async throws -> [CampusLocation] {
        if let error { throw error }

        return locations.sorted { first, second in
            let firstName = "\(first.campus) \(first.building) \(first.room)"
            let secondName = "\(second.campus) \(second.building) \(second.room)"
            return firstName.compare(secondName, options: .numeric) == .orderedAscending
        }
    }

    func fetchLocation(id: UUID) async throws -> CampusLocation {
        if let error { throw error }
        guard let location = locations.first(where: { $0.id == id }) else {
            throw RepositoryError.locationNotFound
        }
        return location
    }
}
