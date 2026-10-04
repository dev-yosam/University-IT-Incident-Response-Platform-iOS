import CoreData

@MainActor
final class PersistenceController {
    let container: NSPersistentContainer

    init(
        storeURL: URL? = nil,
        modelURL: URL? = Bundle.main.url(forResource: "IncidentModel", withExtension: "momd")
    ) async throws {
        guard let modelURL, let model = NSManagedObjectModel(contentsOf: modelURL) else {
            throw RepositoryError.readFailed
        }
        let container = NSPersistentContainer(name: "IncidentModel", managedObjectModel: model)
        if let storeURL {
            container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        }

        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                container.loadPersistentStores { _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        } catch {
            throw RepositoryError.readFailed
        }

        self.container = container
        container.viewContext.undoManager = nil
        try seedLocationsIfNeeded()
    }

    private func seedLocationsIfNeeded() throws {
        let context = container.viewContext
        do {
            let request = NSFetchRequest<CampusLocationEntity>(entityName: "CampusLocationEntity")
            guard try context.count(for: request) == 0 else { return }

            for building in ["Building 2", "Building 8", "Building 11"] {
                let location = CampusLocationEntity(context: context)
                location.id = UUID()
                location.campus = "UTS"
                location.building = building
                location.room = "Room 101"
            }
            try context.save()
        } catch {
            context.rollback()
            throw RepositoryError.saveFailed
        }
    }
}
