import Foundation

nonisolated struct SharedIncidentSnapshot: Codable, Equatable, Sendable {
    let generatedAt: Date
    let activeIncidentCount: Int
    let incidents: [IncidentSummary]

    struct IncidentSummary: Codable, Equatable, Identifiable, Sendable {
        let id: UUID
        let title: String
        let locationName: String
        let status: IncidentStatus
        let priority: IncidentPriority
        let followUpAt: Date?
    }
}
