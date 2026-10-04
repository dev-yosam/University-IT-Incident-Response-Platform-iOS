import Foundation

nonisolated struct SharedIncidentStore: Sendable {
    static let appGroupID = "group.com.dev-yosam.University-IT-Incident-Response-Platform-iOS"

    private let directoryURL: URL
    private var fileURL: URL { directoryURL.appendingPathComponent("incident-summary.json") }

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
    }

    static func appGroup() throws(Failure) -> SharedIncidentStore {
        guard let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw .sharedContainerUnavailable
        }
        return SharedIncidentStore(directoryURL: url)
    }

    func read() throws(Failure) -> SharedIncidentSnapshot? {
        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(SharedIncidentSnapshot.self, from: data)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        } catch {
            throw .couldNotReadSummary
        }
    }

    func write(_ snapshot: SharedIncidentSnapshot) throws(Failure) {
        do {
            let data = try JSONEncoder().encode(snapshot)
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            // Replace the whole file so readers never receive a partial summary.
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            throw .couldNotWriteSummary
        }
    }

    enum Failure: LocalizedError, Equatable {
        case sharedContainerUnavailable
        case couldNotReadSummary
        case couldNotWriteSummary

        var errorDescription: String? {
            switch self {
            case .sharedContainerUnavailable:
                return "The shared incident summary is unavailable. Open the incident app and try again."
            case .couldNotReadSummary:
                return "The incident summary could not be read. Open the incident app to refresh it."
            case .couldNotWriteSummary:
                return "The incident summary could not be updated. Open the incident app and try again."
            }
        }
    }
}
