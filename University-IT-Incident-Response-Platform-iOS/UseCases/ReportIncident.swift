import Foundation

nonisolated struct ReportIncident: Sendable {
    private let incidentRepository: any IncidentRepository
    private let locationRepository: any CampusLocationRepository
    private let now: @Sendable () -> Date

    init(
        incidentRepository: any IncidentRepository,
        locationRepository: any CampusLocationRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.incidentRepository = incidentRepository
        self.locationRepository = locationRepository
        self.now = now
    }

    func execute(
        title: String,
        details: String,
        locationID: UUID,
        priority: IncidentPriority = .normal
    ) async throws(Failure) -> Incident {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = details.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw .titleRequired }
        guard !details.isEmpty else { throw .detailsRequired }

        do {
            _ = try await locationRepository.fetchLocation(id: locationID)
        } catch RepositoryError.locationNotFound {
            throw .locationNotFound
        } catch {
            throw .couldNotLoadLocation
        }

        do {
            let incident = try Incident(
                title: title,
                details: details,
                locationID: locationID,
                priority: priority,
                createdAt: now()
            )
            try await incidentRepository.createIncident(incident)
            return incident
        } catch {
            throw .couldNotSaveIncident
        }
    }

    enum Failure: LocalizedError, Equatable {
        case titleRequired
        case detailsRequired
        case locationNotFound
        case couldNotLoadLocation
        case couldNotSaveIncident

        var errorDescription: String? {
            switch self {
            case .titleRequired:
                return "The incident needs a title. Enter a short description of the problem."
            case .detailsRequired:
                return "The incident needs more details. Describe what is not working."
            case .locationNotFound:
                return "The selected campus location is no longer available. Choose another location."
            case .couldNotLoadLocation:
                return "The campus location could not be checked. Try selecting the location again."
            case .couldNotSaveIncident:
                return "The incident could not be saved. Keep your details and try reporting it again."
            }
        }
    }
}
