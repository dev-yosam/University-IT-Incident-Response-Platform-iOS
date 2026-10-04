import Foundation

nonisolated struct ScheduleIncidentFollowUp: Sendable {
    private let repository: any IncidentRepository
    private let now: @Sendable () -> Date

    init(
        repository: any IncidentRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }

    func execute(incidentID: UUID, followUpAt: Date) async throws(Failure) -> Incident {
        var incident: Incident
        do {
            incident = try await repository.fetchIncident(id: incidentID)
        } catch RepositoryError.incidentNotFound {
            throw .incidentNotFound
        } catch {
            throw .couldNotLoadIncident
        }

        guard incident.status != .resolved else { throw .alreadyResolved }
        let scheduledAt = now()
        guard followUpAt > scheduledAt else { throw .followUpMustBeInFuture }
        incident.followUpAt = followUpAt
        incident.updatedAt = scheduledAt

        do {
            try await repository.saveIncident(incident, update: nil)
            return incident
        } catch {
            throw .couldNotSaveFollowUp
        }
    }

    enum Failure: LocalizedError, Equatable {
        case incidentNotFound
        case couldNotLoadIncident
        case alreadyResolved
        case followUpMustBeInFuture
        case couldNotSaveFollowUp

        var errorDescription: String? {
            switch self {
            case .incidentNotFound:
                return "This incident could not be found. Return to the incident list and select it again."
            case .couldNotLoadIncident:
                return "The incident could not be loaded. Reopen it before choosing a follow-up time."
            case .alreadyResolved:
                return "This incident is already resolved. Report a new incident if another check is needed."
            case .followUpMustBeInFuture:
                return "The follow-up time must be in the future. Choose a later time."
            case .couldNotSaveFollowUp:
                return "The follow-up time could not be saved. Try scheduling it again."
            }
        }
    }
}
