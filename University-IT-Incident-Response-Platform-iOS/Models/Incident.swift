import Foundation

nonisolated struct Incident: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let details: String
    let locationID: UUID
    let priority: IncidentPriority
    let createdAt: Date
    var status: IncidentStatus
    var updatedAt: Date
    var followUpAt: Date?
    var resolvedAt: Date?

    init(
        id: UUID = UUID(),
        title: String,
        details: String,
        locationID: UUID,
        priority: IncidentPriority = .normal,
        status: IncidentStatus = .reported,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        followUpAt: Date? = nil,
        resolvedAt: Date? = nil
    ) throws {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let details = details.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            throw IncidentValidationError.emptyTitle
        }
        guard !details.isEmpty else {
            throw IncidentValidationError.emptyDetails
        }

        self.id = id
        self.title = title
        self.details = details
        self.locationID = locationID
        self.priority = priority
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.followUpAt = followUpAt
        self.resolvedAt = resolvedAt
    }
}
