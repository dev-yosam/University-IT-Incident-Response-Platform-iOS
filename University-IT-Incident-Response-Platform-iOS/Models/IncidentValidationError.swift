import Foundation

nonisolated enum IncidentValidationError: LocalizedError, Equatable {
    case emptyTitle
    case emptyDetails
    case emptyUpdateNote
    case emptyCampus
    case emptyBuilding
    case emptyRoom

    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "The incident title is empty. Enter a short title for the problem."
        case .emptyDetails:
            return "The incident details are empty. Describe what is not working."
        case .emptyUpdateNote:
            return "The update note is empty. Describe the work done on this incident."
        case .emptyCampus:
            return "The campus name is empty. Enter the campus for this location."
        case .emptyBuilding:
            return "The building name is empty. Enter the building for this location."
        case .emptyRoom:
            return "The room name is empty. Enter a room name or number."
        }
    }
}
