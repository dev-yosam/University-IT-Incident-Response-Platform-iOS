import Foundation

nonisolated struct ResolveIncident: Sendable {
    private let repository: any IncidentRepository
    private let now: @Sendable () -> Date

    init(
        repository: any IncidentRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }

    func execute(incidentID: UUID, resolution: String) async throws(Failure) -> Incident {
        let resolution = resolution.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !resolution.isEmpty else { throw .resolutionRequired }

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
            throw .responseNotStarted
        case .inProgress:
            break
        case .resolved:
            throw .alreadyResolved
        }

        let resolvedAt = now()
        incident.status = .resolved
        incident.updatedAt = resolvedAt
        incident.resolvedAt = resolvedAt
        incident.followUpAt = nil

        do {
            let update = try IncidentUpdate(
                incidentID: incident.id,
                note: resolution,
                status: .resolved,
                createdAt: resolvedAt
            )
            try await repository.saveIncident(incident, update: update)
            return incident
        } catch {
            throw .couldNotResolveIncident
        }
    }

    enum Failure: LocalizedError, Equatable {
        case resolutionRequired
        case incidentNotFound
        case couldNotLoadIncident
        case responseNotStarted
        case alreadyResolved
        case couldNotResolveIncident

        var errorDescription: String? {
            switch self {
            case .resolutionRequired:
                return "The resolution note is empty. Describe how the problem was fixed before closing the incident."
            case .incidentNotFound:
                return "This incident could not be found. Return to the incident list and select it again."
            case .couldNotLoadIncident:
                return "The incident could not be loaded. Keep your resolution note and reopen the incident."
            case .responseNotStarted:
                return "Work has not started on this incident. Start the response before recording a resolution."
            case .alreadyResolved:
                return "This incident is already resolved. Check its history for the recorded resolution."
            case .couldNotResolveIncident:
                return "The resolution could not be saved. Keep your note and try closing the incident again."
            }
        }
    }
}
