import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct ScheduleIncidentFollowUpTests {
    @Test func openIncidentCanReceiveAFutureFollowUpTime() async throws {
        let repository = MockIncidentRepository()
        let incident = try IncidentTestData.makeIncident(
            status: .inProgress, followUpAt: IncidentTestData.now.addingTimeInterval(7200)
        )
        try await repository.createIncident(incident)
        let schedule = ScheduleIncidentFollowUp(repository: repository, now: { IncidentTestData.now })
        let followUpAt = IncidentTestData.now.addingTimeInterval(1)

        let scheduled = try await schedule.execute(incidentID: incident.id, followUpAt: followUpAt)

        #expect(scheduled.followUpAt == followUpAt)
        #expect(scheduled.status == .inProgress)
        #expect(scheduled.updatedAt == IncidentTestData.now)
        #expect(try await repository.fetchIncident(id: incident.id) == scheduled)
        #expect(try await repository.fetchUpdates(for: incident.id).isEmpty)
    }

    @Test func followUpAtCurrentTimeIsRejected() async throws {
        let repository = MockIncidentRepository()
        let incident = try IncidentTestData.makeIncident(followUpAt: IncidentTestData.now.addingTimeInterval(3600))
        try await repository.createIncident(incident)
        let schedule = ScheduleIncidentFollowUp(repository: repository, now: { IncidentTestData.now })

        await #expect(throws: ScheduleIncidentFollowUp.Failure.followUpMustBeInFuture) {
            try await schedule.execute(incidentID: incident.id, followUpAt: IncidentTestData.now)
        }
        #expect(try await repository.fetchIncident(id: incident.id) == incident)
    }
}
