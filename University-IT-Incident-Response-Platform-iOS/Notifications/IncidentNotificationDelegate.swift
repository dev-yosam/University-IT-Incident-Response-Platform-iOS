import UIKit
import UserNotifications

final class IncidentNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let openApp = UNNotificationAction(identifier: "OPEN_INCIDENT_APP", title: "Open app", options: .foreground)
        center.setNotificationCategories([
            UNNotificationCategory(identifier: IncidentReminderContent.categoryID,
                                   actions: [openApp], intentIdentifiers: [], options: [])
        ])
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
