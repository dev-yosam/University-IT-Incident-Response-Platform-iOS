import CoreData

@MainActor
final class CoreDataCampusLocationRepository: CampusLocationRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    @MainActor
    func fetchLocations() async throws -> [CampusLocation] {
        do {
            let request = NSFetchRequest<CampusLocationEntity>(entityName: "CampusLocationEntity")
            return try context.fetch(request).map { try $0.asLocation() }.sorted { first, second in
                let firstName = "\(first.campus) \(first.building) \(first.room)"
                let secondName = "\(second.campus) \(second.building) \(second.room)"
                return firstName.compare(secondName, options: .numeric) == .orderedAscending
            }
        } catch {
            throw RepositoryError.readFailed
        }
    }

    @MainActor
    func fetchLocation(id: UUID) async throws -> CampusLocation {
        do {
            let request = NSFetchRequest<CampusLocationEntity>(entityName: "CampusLocationEntity")
            request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
            request.fetchLimit = 1
            guard let location = try context.fetch(request).first else {
                throw RepositoryError.locationNotFound
            }
            return try location.asLocation()
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.readFailed
        }
    }
}
