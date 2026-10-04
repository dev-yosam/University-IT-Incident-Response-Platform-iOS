import Foundation

@MainActor
final class AppDependencies {
    private let persistence: PersistenceController
    private let incidents: any IncidentRepository
    private let locations: any CampusLocationRepository
    private let widgetUpdater: IncidentWidgetUpdater

    var widgetErrorMessage: String? { widgetUpdater.errorMessage }

    private init(persistence: PersistenceController) {
        self.persistence = persistence
        let locations = persistence.makeLocationRepository()
        let updater = IncidentWidgetUpdater(incidents: persistence.makeIncidentRepository(), locations: locations)
        self.locations = locations
        widgetUpdater = updater
        incidents = persistence.makeIncidentRepository(onSave: { await updater.refresh() })
    }

    static func load() async throws -> AppDependencies {
        let persistence = try await PersistenceController()
        let dependencies = AppDependencies(persistence: persistence)
        await dependencies.refreshWidget()
        return dependencies
    }

    func refreshWidget() async {
        await widgetUpdater.refresh()
    }

    func makeIncidentList(scope: GetIncidents.Scope) -> IncidentListViewModel {
        IncidentListViewModel(scope: scope, getIncidents: GetIncidents(repository: incidents))
    }

    func makeReportIncident() -> ReportIncidentViewModel {
        ReportIncidentViewModel(
            getLocations: GetCampusLocations(repository: locations),
            reportIncident: ReportIncident(incidentRepository: incidents, locationRepository: locations)
        )
    }

    func makeIncidentDetail(id: UUID) -> IncidentDetailViewModel {
        IncidentDetailViewModel(
            incidentID: id,
            getDetails: GetIncidentDetails(incidentRepository: incidents, locationRepository: locations),
            startResponse: StartIncidentResponse(repository: incidents),
            scheduleFollowUp: ScheduleIncidentFollowUp(repository: incidents)
        )
    }

    func makeIncidentUpdate(id: UUID, mode: UpdateIncidentViewModel.Mode) -> UpdateIncidentViewModel {
        UpdateIncidentViewModel(
            incidentID: id, mode: mode,
            addUpdate: AddIncidentUpdate(repository: incidents),
            resolveIncident: ResolveIncident(repository: incidents)
        )
    }
}
