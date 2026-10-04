import Foundation

nonisolated struct AddIncidentUpdate: Sendable {
    private let repository: any IncidentRepository
    private let now: @Sendable () -> Date

    init(
        repository: any IncidentRepository,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.repository = repository
        self.now = now
    }

    func execute(incidentID: UUID, note: String) async throws(Failure) -> Incident {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !note.isEmpty else { throw .noteRequired }

        var incident: Incident
        do {
            incident = try await repository.fetchIncident(id: incidentID)
        } catch RepositoryError.incidentNotFound {
            throw .incidentNotFound
        } catch {
            throw .couldNotLoadIncident
        }

        guard incident.status != .resolved else { throw .alreadyResolved }
        let recordedAt = now()
        incident.updatedAt = recordedAt

        do {
            let update = try IncidentUpdate(
                incidentID: incident.id,
                note: note,
                status: incident.status,
                createdAt: recordedAt
            )
            try await repository.saveIncident(incident, update: update)
            return incident
        } catch {
            throw .couldNotSaveUpdate
        }
    }

    enum Failure: LocalizedError, Equatable {
        case noteRequired
        case incidentNotFound
        case couldNotLoadIncident
        case alreadyResolved
        case couldNotSaveUpdate

        var errorDescription: String? {
            switch self {
            case .noteRequired:
                return "The update note is empty. Describe what you checked or changed."
            case .incidentNotFound:
                return "This incident could not be found. Return to the incident list and select it again."
            case .couldNotLoadIncident:
                return "The incident could not be loaded. Keep your note and reopen the incident."
            case .alreadyResolved:
                return "This incident is already resolved. Report a new incident if more work is needed."
            case .couldNotSaveUpdate:
                return "Your update could not be saved. Keep your note and try adding it again."
            }
        }
    }
}
