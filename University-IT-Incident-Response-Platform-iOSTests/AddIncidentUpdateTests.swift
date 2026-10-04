import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct AddIncidentUpdateTests {
    @Test func addingNotePreservesIncidentStatus() async throws {
        let repository = MockIncidentRepository()
        let incident = try IncidentTestData.makeIncident(status: .inProgress)
        try await repository.createIncident(incident)
        let addUpdate = AddIncidentUpdate(repository: repository, now: { IncidentTestData.now })

        let updated = try await addUpdate.execute(incidentID: incident.id, note: "  Checked the display cable.\n")
        let updates = try await repository.fetchUpdates(for: incident.id)
        let update = try #require(updates.first)

        #expect(updated.status == .inProgress)
        #expect(updated.updatedAt == IncidentTestData.now)
        #expect(try await repository.fetchIncident(id: incident.id) == updated)
        #expect(updates.count == 1)
        #expect(update.note == "Checked the display cable.")
        #expect(update.status == .inProgress)
        #expect(update.incidentID == incident.id)
        #expect(update.createdAt == updated.updatedAt)
    }
}
