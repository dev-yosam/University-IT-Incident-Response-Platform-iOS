import Foundation
import Observation

@MainActor
@Observable
final class ReportIncidentViewModel {
    var title = ""
    var details = ""
    var selectedLocationID: UUID?
    var priority: IncidentPriority = .normal

    private(set) var locations: [CampusLocation] = []
    private(set) var isLoading = false
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var createdIncident: Incident?

    private let getLocations: GetCampusLocations
    private let reportIncident: ReportIncident

    init(getLocations: GetCampusLocations, reportIncident: ReportIncident) {
        self.getLocations = getLocations
        self.reportIncident = reportIncident
    }

    func loadLocations() async {
        guard !isLoading, !isSaving else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            locations = try await getLocations.execute()
            if !locations.contains(where: { $0.id == selectedLocationID }) {
                selectedLocationID = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func submit() async -> Bool {
        guard !isSaving, !isLoading, createdIncident == nil else { return false }
        errorMessage = nil
        guard let selectedLocationID else {
            errorMessage = "Choose a campus location before reporting the incident."
            return false
        }

        isSaving = true
        defer { isSaving = false }
        do {
            createdIncident = try await reportIncident.execute(
                title: title, details: details, locationID: selectedLocationID, priority: priority
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
