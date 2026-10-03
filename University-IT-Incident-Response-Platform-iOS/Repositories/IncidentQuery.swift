import Foundation

nonisolated struct IncidentQuery: Sendable {
    // An empty set matches no incidents.
    var statuses: Set<IncidentStatus> = Set(IncidentStatus.allCases)
    var locationID: UUID?
    var priority: IncidentPriority?
    // When set, match only follow-ups at or before this time.
    var followUpDueBy: Date?
}
