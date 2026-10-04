import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct ResolveIncidentTests {
    @Test func resolvingIncidentRecordsResolutionAndClearsFollowUp() async throws {
        let repository = MockIncidentRepository()
        let incident = try IncidentTestData.makeIncident(
            status: .inProgress, followUpAt: IncidentTestData.now.addingTimeInterval(3600)
        )
        try await repository.createIncident(incident)
        let resolve = ResolveIncident(repository: repository, now: { IncidentTestData.now })

        let resolved = try await resolve.execute(incidentID: incident.id, resolution: "  Replaced the display cable.\n")
        let updates = try await repository.fetchUpdates(for: incident.id)
        let update = try #require(updates.first)

        #expect(resolved.status == .resolved)
        #expect(resolved.resolvedAt == IncidentTestData.now)
        #expect(resolved.updatedAt == IncidentTestData.now)
        #expect(resolved.followUpAt == nil)
        #expect(try await repository.fetchIncident(id: incident.id) == resolved)
        #expect(updates.count == 1)
        #expect(update.note == "Replaced the display cable.")
        #expect(update.status == .resolved)
        #expect(update.incidentID == incident.id)
        #expect(update.createdAt == resolved.resolvedAt)
    }

    @Test func failedResolutionKeepsIncidentOpenAndPreservesFollowUp() async throws {
        let repository = MockIncidentRepository()
        let incident = try IncidentTestData.makeIncident(
            status: .inProgress, followUpAt: IncidentTestData.now.addingTimeInterval(3600)
        )
        try await repository.createIncident(incident)
        await repository.simulateErrors(save: .saveFailed)

        await #expect(throws: ResolveIncident.Failure.couldNotResolveIncident) {
            try await ResolveIncident(repository: repository).execute(incidentID: incident.id, resolution: "Replaced the cable.")
        }
        #expect(try await repository.fetchIncident(id: incident.id) == incident)
        #expect(try await repository.fetchUpdates(for: incident.id).isEmpty)
    }
}
