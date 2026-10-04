import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct IncidentReadingTests {
    @Test func incidentListsSeparateActiveWorkFromResolvedHistory() async throws {
        let repository = MockIncidentRepository()
        let reported = try IncidentTestData.makeIncident()
        let inProgress = try IncidentTestData.makeIncident(status: .inProgress)
        let resolved = try IncidentTestData.makeIncident(status: .resolved)
        for incident in [reported, inProgress, resolved] {
            try await repository.createIncident(incident)
        }
        let getIncidents = GetIncidents(repository: repository)

        let active = try await getIncidents.execute(scope: .active)
        let history = try await getIncidents.execute(scope: .resolved)

        #expect(Set(active.map(\.id)) == [reported.id, inProgress.id])
        #expect(history == [resolved])
    }

    @Test func incidentDetailsIncludeItsCampusLocationAndProgressNotes() async throws {
        let location = try IncidentTestData.makeLocation()
        let repository = MockIncidentRepository()
        let incident = try Incident(
            title: "Projector has no image", details: "The screen stays blank.", locationID: location.id
        )
        let update = try IncidentUpdate(
            incidentID: incident.id, note: "Checked the display cable.", status: incident.status
        )
        try await repository.createIncident(incident)
        try await repository.saveIncident(incident, update: update)
        let getDetails = GetIncidentDetails(
            incidentRepository: repository,
            locationRepository: MockCampusLocationRepository(locations: [location])
        )

        let details = try await getDetails.execute(incidentID: incident.id)

        #expect(details.incident == incident)
        #expect(details.location == location)
        #expect(details.updates == [update])
    }

    @Test func reportingLocationsCannotBeEmpty() async {
        let getLocations = GetCampusLocations(repository: MockCampusLocationRepository())

        await #expect(throws: GetCampusLocations.Failure.noLocationsAvailable) {
            try await getLocations.execute()
        }
    }
}
