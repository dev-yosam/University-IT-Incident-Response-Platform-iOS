import Foundation

@MainActor
final class AppDependencies {
    private let persistence: PersistenceController
    private let incidents: any IncidentRepository
    private let locations: any CampusLocationRepository
    private let widgetUpdater: IncidentWidgetUpdater
    private let reminderScheduler: IncidentReminderScheduler

    var widgetErrorMessage: String? { widgetUpdater.errorMessage }
    var reminderErrorMessage: String? { reminderScheduler.errorMessage }

    private init(persistence: PersistenceController) {
        self.persistence = persistence
        let locations = persistence.makeLocationRepository()
        let updater = IncidentWidgetUpdater(incidents: persistence.makeIncidentRepository(), locations: locations)
        let reminders = IncidentReminderScheduler(incidents: persistence.makeIncidentRepository(), locations: locations)
        self.locations = locations
        widgetUpdater = updater
        reminderScheduler = reminders
        incidents = persistence.makeIncidentRepository(onSave: {
            await updater.refresh()
            await reminders.refresh()
        })
    }

    static func load() async throws -> AppDependencies {
        let persistence = try await PersistenceController()
        let dependencies = AppDependencies(persistence: persistence)
        await dependencies.refreshExtensions()
        return dependencies
    }

    func refreshWidget() async {
        await widgetUpdater.refresh()
    }

    func refreshExtensions() async {
        await widgetUpdater.refresh()
        await reminderScheduler.refresh()
    }

    func enableReminders() async {
        await reminderScheduler.enableReminders()
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
            scheduleFollowUp: ScheduleIncidentFollowUp(repository: incidents),
            enableReminders: { [reminderScheduler] in await reminderScheduler.enableReminders() }
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
