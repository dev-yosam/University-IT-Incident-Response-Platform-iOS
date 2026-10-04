import Foundation
@testable import University_IT_Incident_Response_Platform_iOS

enum IncidentTestData {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static func makeLocation() throws -> CampusLocation {
        try CampusLocation(campus: "UTS", building: "Building 11", room: "Room 101")
    }

    static func makeIncident(
        status: IncidentStatus = .reported,
        followUpAt: Date? = nil
    ) throws -> Incident {
        let createdAt = now.addingTimeInterval(-3600)
        return try Incident(
            title: "Projector has no image",
            details: "The screen stays blank after connecting a laptop.",
            locationID: UUID(),
            status: status,
            createdAt: createdAt,
            followUpAt: followUpAt,
            resolvedAt: status == .resolved ? createdAt : nil
        )
    }
}
