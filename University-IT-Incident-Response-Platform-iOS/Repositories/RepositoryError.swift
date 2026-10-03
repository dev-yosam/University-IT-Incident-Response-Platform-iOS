import Foundation

nonisolated enum RepositoryError: LocalizedError, Equatable {
    case incidentNotFound
    case locationNotFound
    case incidentAlreadyExists
    case updateAlreadyExists
    case updateDoesNotMatchIncident
    case readFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .incidentNotFound:
            return "This incident could not be found. Return to the incident list and select it again."
        case .locationNotFound:
            return "This campus location could not be found. Choose another location."
        case .incidentAlreadyExists:
            return "This incident has already been saved. Open it from the incident list."
        case .updateAlreadyExists:
            return "This update has already been saved. Check the incident history before adding it again."
        case .updateDoesNotMatchIncident:
            return "This update does not match the incident. Reopen the incident and add the update again."
        case .readFailed:
            return "Campus support records could not be loaded. Try opening the list again."
        case .saveFailed:
            return "Your incident changes could not be saved. Keep your notes and try again."
        }
    }
}
