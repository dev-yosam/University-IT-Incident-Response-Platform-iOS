import Foundation

actor MockIncidentRepository: IncidentRepository {
    private var incidents: [UUID: Incident] = [:]
    private var updates: [UUID: IncidentUpdate] = [:]
    private var readError: RepositoryError?
    private var saveError: RepositoryError?

    func simulateErrors(read: RepositoryError? = nil, save: RepositoryError? = nil) {
        readError = read
        saveError = save
    }

    func fetchIncidents(matching query: IncidentQuery) async throws -> [Incident] {
        if let readError { throw readError }

        return incidents.values.filter { incident in
            guard query.statuses.contains(incident.status) else { return false }
            if let locationID = query.locationID, incident.locationID != locationID {
                return false
            }
            if let priority = query.priority, incident.priority != priority {
                return false
            }
            if let dueBy = query.followUpDueBy {
                guard let followUpAt = incident.followUpAt, followUpAt <= dueBy else {
                    return false
                }
            }
            return true
        }.sorted { first, second in
            if first.createdAt == second.createdAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.createdAt > second.createdAt
        }
    }

    func fetchIncident(id: UUID) async throws -> Incident {
        if let readError { throw readError }
        guard let incident = incidents[id] else {
            throw RepositoryError.incidentNotFound
        }
        return incident
    }

    func createIncident(_ incident: Incident) async throws {
        if let saveError { throw saveError }
        guard incidents[incident.id] == nil else {
            throw RepositoryError.incidentAlreadyExists
        }
        incidents[incident.id] = incident
    }

    func saveIncident(_ incident: Incident, update: IncidentUpdate?) async throws {
        if let saveError { throw saveError }
        guard incidents[incident.id] != nil else {
            throw RepositoryError.incidentNotFound
        }
        if let update {
            guard update.incidentID == incident.id, update.status == incident.status else {
                throw RepositoryError.updateDoesNotMatchIncident
            }
            guard updates[update.id] == nil else {
                throw RepositoryError.updateAlreadyExists
            }
        }

        incidents[incident.id] = incident
        if let update {
            updates[update.id] = update
        }
    }

    func fetchUpdates(for incidentID: UUID) async throws -> [IncidentUpdate] {
        if let readError { throw readError }
        guard incidents[incidentID] != nil else {
            throw RepositoryError.incidentNotFound
        }

        return updates.values.filter { $0.incidentID == incidentID }.sorted { first, second in
            if first.createdAt == second.createdAt {
                return first.id.uuidString < second.id.uuidString
            }
            return first.createdAt < second.createdAt
        }
    }
}
