import CoreData

@MainActor
final class CoreDataIncidentRepository: IncidentRepository {
    private let context: NSManagedObjectContext
    private let onSave: @MainActor () async -> Void

    init(context: NSManagedObjectContext, onSave: @escaping @MainActor () async -> Void = {}) {
        self.context = context
        self.onSave = onSave
    }

    // Protocol methods need explicit isolation to stay on the view context's queue.
    @MainActor
    func fetchIncidents(matching query: IncidentQuery) async throws -> [Incident] {
        do {
            let request = NSFetchRequest<IncidentEntity>(entityName: "IncidentEntity")
            var predicates = [NSPredicate(format: "status IN %@", query.statuses.map(\.rawValue) as NSArray)]
            if let locationID = query.locationID {
                predicates.append(NSPredicate(format: "location.id == %@", locationID as NSUUID))
            }
            if let priority = query.priority {
                predicates.append(NSPredicate(format: "priority == %@", priority.rawValue))
            }
            if let dueBy = query.followUpDueBy {
                predicates.append(NSPredicate(format: "followUpAt != nil AND followUpAt <= %@", dueBy as NSDate))
            }
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: false),
                NSSortDescriptor(key: "id", ascending: true)
            ]
            return try context.fetch(request).map { try $0.asIncident() }
        } catch {
            throw RepositoryError.readFailed
        }
    }

    @MainActor
    func fetchIncident(id: UUID) async throws -> Incident {
        do {
            guard let entity = try findIncident(id: id) else {
                throw RepositoryError.incidentNotFound
            }
            return try entity.asIncident()
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.readFailed
        }
    }

    @MainActor
    func createIncident(_ incident: Incident) async throws {
        do {
            guard try findIncident(id: incident.id) == nil else {
                throw RepositoryError.incidentAlreadyExists
            }
            let location = try findLocation(id: incident.locationID)
            let entity = IncidentEntity(context: context)
            entity.apply(incident, location: location)
            try context.save()
        } catch {
            context.rollback()
            throw (error as? RepositoryError) ?? .saveFailed
        }
        await onSave()
    }

    @MainActor
    func saveIncident(_ incident: Incident, update: IncidentUpdate?) async throws {
        do {
            guard let entity = try findIncident(id: incident.id) else {
                throw RepositoryError.incidentNotFound
            }
            if let update {
                guard update.incidentID == incident.id, update.status == incident.status else {
                    throw RepositoryError.updateDoesNotMatchIncident
                }
                let request = NSFetchRequest<IncidentUpdateEntity>(entityName: "IncidentUpdateEntity")
                request.predicate = NSPredicate(format: "id == %@", update.id as NSUUID)
                request.fetchLimit = 1
                guard try context.fetch(request).isEmpty else {
                    throw RepositoryError.updateAlreadyExists
                }
            }
            let location = try findLocation(id: incident.locationID)
            entity.apply(incident, location: location)
            if let update {
                let record = IncidentUpdateEntity(context: context)
                record.id = update.id
                record.note = update.note
                record.status = update.status.rawValue
                record.createdAt = update.createdAt
                record.incident = entity
            }
            try context.save()
        } catch {
            context.rollback()
            throw (error as? RepositoryError) ?? .saveFailed
        }
        await onSave()
    }

    @MainActor
    func fetchUpdates(for incidentID: UUID) async throws -> [IncidentUpdate] {
        do {
            guard try findIncident(id: incidentID) != nil else {
                throw RepositoryError.incidentNotFound
            }
            let request = NSFetchRequest<IncidentUpdateEntity>(entityName: "IncidentUpdateEntity")
            request.predicate = NSPredicate(format: "incident.id == %@", incidentID as NSUUID)
            request.sortDescriptors = [
                NSSortDescriptor(key: "createdAt", ascending: true),
                NSSortDescriptor(key: "id", ascending: true)
            ]
            return try context.fetch(request).map { try $0.asUpdate() }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.readFailed
        }
    }

    private func findIncident(id: UUID) throws -> IncidentEntity? {
        let request = NSFetchRequest<IncidentEntity>(entityName: "IncidentEntity")
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func findLocation(id: UUID) throws -> CampusLocationEntity {
        let request = NSFetchRequest<CampusLocationEntity>(entityName: "CampusLocationEntity")
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1
        guard let location = try context.fetch(request).first else {
            throw RepositoryError.locationNotFound
        }
        return location
    }
}
