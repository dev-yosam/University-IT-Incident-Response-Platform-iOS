import Foundation

nonisolated struct GetIncidents: Sendable {
    enum Scope: Sendable {
        case active
        case resolved
    }

    private let repository: any IncidentRepository

    init(repository: any IncidentRepository) {
        self.repository = repository
    }

    func execute(scope: Scope) async throws(Failure) -> [Incident] {
        let statuses: Set<IncidentStatus> = scope == .active ? [.reported, .inProgress] : [.resolved]
        do {
            return try await repository.fetchIncidents(matching: IncidentQuery(statuses: statuses))
        } catch {
            throw .couldNotLoadIncidents
        }
    }

    enum Failure: LocalizedError, Equatable {
        case couldNotLoadIncidents

        var errorDescription: String? {
            "The incident list could not be loaded. Try refreshing it."
        }
    }
}
