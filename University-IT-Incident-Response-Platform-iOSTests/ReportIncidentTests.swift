import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct ReportIncidentTests {
    @Test func reportingIncidentSavesDetailsAndSelectedLocation() async throws {
        let location = try IncidentTestData.makeLocation()
        let repository = MockIncidentRepository()
        let report = ReportIncident(
            incidentRepository: repository,
            locationRepository: MockCampusLocationRepository(locations: [location]),
            now: { IncidentTestData.now }
        )

        let incident = try await report.execute(
            title: "  Projector has no image ",
            details: " The screen stays blank.\n",
            locationID: location.id,
            priority: .high
        )

        #expect(incident.title == "Projector has no image")
        #expect(incident.details == "The screen stays blank.")
        #expect(incident.locationID == location.id)
        #expect(incident.priority == .high)
        #expect(incident.status == .reported)
        #expect(incident.createdAt == IncidentTestData.now)
        #expect(incident.updatedAt == IncidentTestData.now)
        #expect(try await repository.fetchIncident(id: incident.id) == incident)
    }
}
