import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class IncidentReminderScheduler {
    private(set) var errorMessage: String?
    private let incidents: any IncidentRepository
    private let locations: any CampusLocationRepository
    private let center = UNUserNotificationCenter.current()
    private var isRefreshing = false
    private var refreshRequested = false

    init(incidents: any IncidentRepository, locations: any CampusLocationRepository) {
        self.incidents = incidents
        self.locations = locations
    }

    func enableReminders() async {
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
            await refresh()
        } catch {
            errorMessage = "Notification permission could not be checked. Your follow-up time is saved. Try enabling reminders again."
        }
    }

    func refresh() async {
        refreshRequested = true
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        repeat {
            refreshRequested = false
            do {
                try await synchronizeReminders()
            } catch {
                errorMessage = "Follow-up reminders could not be updated. Your incident records are saved. Check reminders again before leaving the app."
            }
        } while refreshRequested
    }

    private func synchronizeReminders() async throws {
        let active = try await incidents.fetchIncidents(matching: IncidentQuery(statuses: [.reported, .inProgress]))
        let followUps = active.compactMap { incident -> (incident: Incident, date: Date)? in
            guard let date = incident.followUpAt else { return nil }
            return (incident, date)
        }
        let now = Date()
        let future = followUps.filter { $0.date > now }.sorted { $0.date < $1.date }
        let settings = await center.notificationSettings()
        let allowed = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
        // Keep the nearest reminders within the system's scheduling limit.
        let desired = allowed ? Array(future.prefix(60)) : []
        var reminders: [IncidentReminderContent] = []
        for (incident, date) in desired {
            let location = try await locations.fetchLocation(id: incident.locationID)
            reminders.append(IncidentReminderContent(
                incidentID: incident.id, title: incident.title,
                locationName: "\(location.building) · \(location.room)",
                priority: incident.priority.rawValue.capitalized, followUpAt: date
            ))
        }
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        guard !refreshRequested else { return }

        let desiredIDs = Set(reminders.map(\.requestID))
        let obsolete = pending.filter {
            $0.identifier.hasPrefix(IncidentReminderContent.requestPrefix) && !desiredIDs.contains($0.identifier)
        }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: obsolete)

        // Remove old alerts when their incident is resolved or its follow-up time changes.
        let outdated = delivered.filter { notification in
            guard notification.request.identifier.hasPrefix(IncidentReminderContent.requestPrefix) else { return false }
            guard let content = IncidentReminderContent(userInfo: notification.request.content.userInfo) else { return true }
            return !followUps.contains { followUp in
                // Notification payloads can lose fractions of a second.
                followUp.incident.id == content.incidentID && abs(followUp.date.timeIntervalSince(content.followUpAt)) < 1
            }
        }.map { $0.request.identifier }
        center.removeDeliveredNotifications(withIdentifiers: outdated)

        for reminder in reminders {
            guard !refreshRequested else { return }
            let content = UNMutableNotificationContent()
            content.title = "Incident follow-up"
            content.subtitle = reminder.title
            content.body = "Check \(reminder.locationName). Open the app to record your progress."
            content.categoryIdentifier = IncidentReminderContent.categoryID
            content.userInfo = reminder.userInfo
            content.sound = .default
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: reminder.followUpAt)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            try await center.add(UNNotificationRequest(identifier: reminder.requestID, content: content, trigger: trigger))
        }

        if !future.isEmpty && settings.authorizationStatus == .denied {
            errorMessage = "Notifications are off. Your follow-up times are saved. Enable notifications in Settings to receive incident reminders."
        } else if future.count > 60 && allowed {
            errorMessage = "Only the next 60 follow-up reminders are scheduled. Open the app after these checks to schedule the remaining reminders."
        } else {
            errorMessage = nil
        }
    }
}
