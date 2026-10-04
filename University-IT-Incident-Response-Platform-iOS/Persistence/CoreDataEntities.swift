import CoreData

@objc(CampusLocationEntity)
nonisolated final class CampusLocationEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var campus: String?
    @NSManaged var building: String?
    @NSManaged var room: String?
    @NSManaged var incidents: NSSet?

    func asLocation() throws -> CampusLocation {
        guard let id, let campus, let building, let room else {
            throw RepositoryError.readFailed
        }
        return try CampusLocation(id: id, campus: campus, building: building, room: room)
    }
}

@objc(IncidentEntity)
nonisolated final class IncidentEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var title: String?
    @NSManaged var details: String?
    @NSManaged var priority: String?
    @NSManaged var status: String?
    @NSManaged var createdAt: Date?
    @NSManaged var updatedAt: Date?
    @NSManaged var followUpAt: Date?
    @NSManaged var resolvedAt: Date?
    @NSManaged var location: CampusLocationEntity?
    @NSManaged var updates: NSSet?

    func asIncident() throws -> Incident {
        guard let id, let title, let details, let locationID = location?.id,
              let priority, let domainPriority = IncidentPriority(rawValue: priority),
              let status, let domainStatus = IncidentStatus(rawValue: status),
              let createdAt, let updatedAt else {
            throw RepositoryError.readFailed
        }
        return try Incident(
            id: id, title: title, details: details, locationID: locationID,
            priority: domainPriority, status: domainStatus,
            createdAt: createdAt, updatedAt: updatedAt,
            followUpAt: followUpAt, resolvedAt: resolvedAt
        )
    }

    func apply(_ incident: Incident, location: CampusLocationEntity) {
        id = incident.id
        title = incident.title
        details = incident.details
        priority = incident.priority.rawValue
        status = incident.status.rawValue
        createdAt = incident.createdAt
        updatedAt = incident.updatedAt
        followUpAt = incident.followUpAt
        resolvedAt = incident.resolvedAt
        self.location = location
    }
}

@objc(IncidentUpdateEntity)
nonisolated final class IncidentUpdateEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var note: String?
    @NSManaged var status: String?
    @NSManaged var createdAt: Date?
    @NSManaged var incident: IncidentEntity?

    func asUpdate() throws -> IncidentUpdate {
        guard let id, let incidentID = incident?.id, let note,
              let status, let domainStatus = IncidentStatus(rawValue: status),
              let createdAt else {
            throw RepositoryError.readFailed
        }
        return try IncidentUpdate(
            id: id, incidentID: incidentID, note: note,
            status: domainStatus, createdAt: createdAt
        )
    }
}
