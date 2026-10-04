import Foundation

nonisolated struct GetIncidentDetails: Sendable {
    struct Details: Sendable {
        let incident: Incident
        let location: CampusLocation
        let updates: [IncidentUpdate]
    }

    private let incidentRepository: any IncidentRepository
    private let locationRepository: any CampusLocationRepository

    init(incidentRepository: any IncidentRepository, locationRepository: any CampusLocationRepository) {
        self.incidentRepository = incidentRepository
        self.locationRepository = locationRepository
    }

    func execute(incidentID: UUID) async throws(Failure) -> Details {
        do {
            let incident = try await incidentRepository.fetchIncident(id: incidentID)
            let location = try await locationRepository.fetchLocation(id: incident.locationID)
            let updates = try await incidentRepository.fetchUpdates(for: incidentID)
            return Details(incident: incident, location: location, updates: updates)
        } catch RepositoryError.incidentNotFound {
            throw .incidentNotFound
        } catch {
            throw .couldNotLoadDetails
        }
    }

    enum Failure: LocalizedError, Equatable {
        case incidentNotFound
        case couldNotLoadDetails

        var errorDescription: String? {
            switch self {
            case .incidentNotFound:
                return "This incident could not be found. Return to the incident list."
            case .couldNotLoadDetails:
                return "The incident details could not be loaded. Try refreshing them."
            }
        }
    }
}
