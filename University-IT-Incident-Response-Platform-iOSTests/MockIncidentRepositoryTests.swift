import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct MockIncidentRepositoryTests {
    @Test func followUpQueryReturnsOnlyOpenIncidentsThatAreDue() async throws {
        let repository = MockIncidentRepository()
        let dueIncident = try IncidentTestData.makeIncident(
            status: .inProgress, followUpAt: IncidentTestData.now
        )
        let futureIncident = try IncidentTestData.makeIncident(
            followUpAt: IncidentTestData.now.addingTimeInterval(3600)
        )
        let resolvedIncident = try IncidentTestData.makeIncident(
            status: .resolved, followUpAt: IncidentTestData.now
        )
        let incidentWithoutFollowUp = try IncidentTestData.makeIncident()
        for incident in [futureIncident, resolvedIncident, incidentWithoutFollowUp, dueIncident] {
            try await repository.createIncident(incident)
        }
        let query = IncidentQuery(
            statuses: [.reported, .inProgress], followUpDueBy: IncidentTestData.now
        )

        #expect(try await repository.fetchIncidents(matching: query) == [dueIncident])
    }
}
