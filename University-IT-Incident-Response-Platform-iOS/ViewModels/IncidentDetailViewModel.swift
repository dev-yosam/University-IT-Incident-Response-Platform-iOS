import Foundation
import Observation

@MainActor
@Observable
final class IncidentDetailViewModel {
    let incidentID: UUID
    private(set) var incident: Incident?
    private(set) var location: CampusLocation?
    private(set) var updates: [IncidentUpdate] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?

    private let getDetails: GetIncidentDetails
    private let startResponse: StartIncidentResponse
    private let scheduleFollowUp: ScheduleIncidentFollowUp

    init(
        incidentID: UUID,
        getDetails: GetIncidentDetails,
        startResponse: StartIncidentResponse,
        scheduleFollowUp: ScheduleIncidentFollowUp
    ) {
        self.incidentID = incidentID
        self.getDetails = getDetails
        self.startResponse = startResponse
        self.scheduleFollowUp = scheduleFollowUp
    }

    func load() async {
        guard !isLoading, !isSaving else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        await refreshDetails()
    }

    func startWork() async {
        guard !isLoading, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            incident = try await startResponse.execute(incidentID: incidentID)
            await refreshDetails()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func scheduleFollowUp(at date: Date) async {
        guard !isLoading, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            incident = try await scheduleFollowUp.execute(incidentID: incidentID, followUpAt: date)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshDetails() async {
        do {
            let details = try await getDetails.execute(incidentID: incidentID)
            incident = details.incident
            location = details.location
            updates = details.updates
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
