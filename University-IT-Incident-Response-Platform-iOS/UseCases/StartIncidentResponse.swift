import Foundation

nonisolated struct StartIncidentResponse: Sendable {
    private let repository: any IncidentRepository
    private let now: @Sendable () -> Date

    init(
        repository: any IncidentRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }

    func execute(incidentID: UUID) async throws(Failure) -> Incident {
        var incident: Incident
        do {
            incident = try await repository.fetchIncident(id: incidentID)
        } catch RepositoryError.incidentNotFound {
            throw .incidentNotFound
        } catch {
            throw .couldNotLoadIncident
        }

        switch incident.status {
        case .reported:
            break
        case .inProgress:
            throw .alreadyInProgress
        case .resolved:
            throw .alreadyResolved
        }

        let startedAt = now()
        incident.status = .inProgress
        incident.updatedAt = startedAt

        do {
            let update = try IncidentUpdate(
                incidentID: incident.id,
                note: "Started working on this incident.",
                status: .inProgress,
                createdAt: startedAt
            )
            try await repository.saveIncident(incident, update: update)
            return incident
        } catch {
            throw .couldNotStartResponse
        }
    }

    enum Failure: LocalizedError, Equatable {
        case incidentNotFound
        case couldNotLoadIncident
        case alreadyInProgress
        case alreadyResolved
        case couldNotStartResponse

        var errorDescription: String? {
            switch self {
            case .incidentNotFound:
                return "This incident could not be found. Return to the incident list and select it again."
            case .couldNotLoadIncident:
                return "The incident could not be loaded. Reopen it before starting work."
            case .alreadyInProgress:
                return "Work has already started on this incident. Add a progress note instead."
            case .alreadyResolved:
                return "This incident is already resolved. Report a new incident if the problem returns."
            case .couldNotStartResponse:
                return "The start of your work could not be saved. Try starting the response again."
            }
        }
    }
}
