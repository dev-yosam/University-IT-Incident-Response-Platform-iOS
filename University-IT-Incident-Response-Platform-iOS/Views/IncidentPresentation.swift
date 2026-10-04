import SwiftUI

extension IncidentStatus {
    var title: String {
        switch self {
        case .reported: "Reported"
        case .inProgress: "In progress"
        case .resolved: "Resolved"
        }
    }
}

extension IncidentPriority {
    var title: String {
        switch self {
        case .low: "Low"
        case .normal: "Normal"
        case .high: "High"
        }
    }
}

extension CampusLocation {
    var displayName: String { "\(campus) · \(building) · \(room)" }
}

struct IncidentErrorView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .foregroundStyle(.red)
            .accessibilityIdentifier("incidentError")
    }
}
