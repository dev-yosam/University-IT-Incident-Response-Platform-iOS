import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct University_IT_Incident_Response_Platform_iOSTests {
    @Test func startingResponseSavesProgressAndHistoryTogether() async throws {
        let repository = MockIncidentRepository()
        let incident = try IncidentTestData.makeIncident()
        try await repository.createIncident(incident)
        let start = StartIncidentResponse(repository: repository, now: { IncidentTestData.now })

        let started = try await start.execute(incidentID: incident.id)
        let updates = try await repository.fetchUpdates(for: incident.id)
        let update = try #require(updates.first)

        #expect(started.status == .inProgress)
        #expect(started.createdAt == incident.createdAt)
        #expect(started.updatedAt == IncidentTestData.now)
        #expect(try await repository.fetchIncident(id: incident.id) == started)
        #expect(updates.count == 1)
        #expect(update.incidentID == incident.id)
        #expect(update.status == .inProgress)
        #expect(update.createdAt == started.updatedAt)
        #expect(!update.note.isEmpty)
    }
}
