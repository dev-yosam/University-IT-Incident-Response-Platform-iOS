import Foundation

nonisolated protocol IncidentRepository: Sendable {
    // Return newest incidents first, using IDs to break ties.
    func fetchIncidents(matching query: IncidentQuery) async throws -> [Incident]
    func fetchIncident(id: UUID) async throws -> Incident
    func createIncident(_ incident: Incident) async throws

    // Save the incident and its update together, or leave both unchanged.
    func saveIncident(_ incident: Incident, update: IncidentUpdate?) async throws

    // Return oldest updates first, using IDs to break ties.
    func fetchUpdates(for incidentID: UUID) async throws -> [IncidentUpdate]
}
