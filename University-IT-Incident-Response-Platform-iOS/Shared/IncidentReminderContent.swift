import Foundation

nonisolated struct IncidentReminderContent: Equatable, Sendable {
    static let categoryID = "INCIDENT_FOLLOW_UP"
    static let requestPrefix = "incident-follow-up."

    let incidentID: UUID
    let title: String
    let locationName: String
    let priority: String
    let followUpAt: Date

    var requestID: String { Self.requestPrefix + incidentID.uuidString }

    var userInfo: [String: Any] {
        ["incidentID": incidentID.uuidString, "incidentTitle": title,
         "locationName": locationName, "priority": priority,
         "followUpAt": followUpAt.timeIntervalSince1970]
    }

    init(incidentID: UUID, title: String, locationName: String, priority: String, followUpAt: Date) {
        self.incidentID = incidentID
        self.title = title
        self.locationName = locationName
        self.priority = priority
        self.followUpAt = followUpAt
    }

    init?(userInfo: [AnyHashable: Any]) {
        guard let id = userInfo["incidentID"] as? String, let incidentID = UUID(uuidString: id),
              let title = userInfo["incidentTitle"] as? String, !title.isEmpty,
              let location = userInfo["locationName"] as? String, !location.isEmpty,
              let priority = userInfo["priority"] as? String,
              let timestamp = userInfo["followUpAt"] as? Double, timestamp.isFinite else { return nil }
        self.init(incidentID: incidentID, title: title, locationName: location,
                  priority: priority, followUpAt: Date(timeIntervalSince1970: timestamp))
    }
}
