import Foundation

@MainActor
final class AppDependencies {
    private let persistence: PersistenceController
    private let incidents: any IncidentRepository
    private let locations: any CampusLocationRepository

    private init(persistence: PersistenceController) {
        self.persistence = persistence
        incidents = persistence.makeIncidentRepository()
        locations = persistence.makeLocationRepository()
    }

    static func load() async throws -> AppDependencies {
        let persistence = try await PersistenceController()
        return AppDependencies(persistence: persistence)
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
