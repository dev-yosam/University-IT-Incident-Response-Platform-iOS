import Foundation
import Observation
import WidgetKit

@MainActor
@Observable
final class IncidentWidgetUpdater {
    private(set) var errorMessage: String?
    private var isRefreshing = false
    private var refreshRequested = false
    private let incidents: any IncidentRepository
    private let locations: any CampusLocationRepository
    private let store: SharedIncidentStore?

    init(incidents: any IncidentRepository, locations: any CampusLocationRepository, store: SharedIncidentStore? = nil) {
        self.incidents = incidents
        self.locations = locations
        self.store = store
    }

    func refresh() async {
        refreshRequested = true
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        repeat {
            refreshRequested = false
            do {
                let snapshot = try await makeSnapshot()
                // A save during a fetch requires a fresh snapshot before publishing.
                if refreshRequested { continue }
                let destination = try store ?? SharedIncidentStore.appGroup()
                try destination.write(snapshot)
                WidgetCenter.shared.reloadTimelines(ofKind: SharedIncidentSnapshot.widgetKind)
                errorMessage = nil
            } catch {
                errorMessage = "The Home Screen incident summary could not be updated. Your records are still available in the app. Try refreshing the summary."
            }
        } while refreshRequested
    }

    private func makeSnapshot() async throws -> SharedIncidentSnapshot {
        let active = try await incidents.fetchIncidents(
            matching: IncidentQuery(statuses: [.reported, .inProgress])
        )
        let ordered = active.sorted { first, second in
            let firstFollowUp = first.followUpAt ?? .distantFuture
            let secondFollowUp = second.followUpAt ?? .distantFuture
            if firstFollowUp != secondFollowUp { return firstFollowUp < secondFollowUp }
            if first.createdAt != second.createdAt { return first.createdAt > second.createdAt }
            return first.id.uuidString < second.id.uuidString
        }
        var summaries: [SharedIncidentSnapshot.IncidentSummary] = []
        for incident in ordered.prefix(2) {
            let location = try await locations.fetchLocation(id: incident.locationID)
            summaries.append(SharedIncidentSnapshot.IncidentSummary(
                id: incident.id,
                title: incident.title,
                locationName: "\(location.building) · \(location.room)",
                status: incident.status,
                priority: incident.priority,
                followUpAt: incident.followUpAt
            ))
        }
        return SharedIncidentSnapshot(generatedAt: Date(), activeIncidentCount: active.count, incidents: summaries)
    }
}
