import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class SettingsViewModel {
    private(set) var notificationStatus = "Checking…"
    private(set) var notificationAdvice = ""

    var version: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
        return "\(version) (\(build))"
    }

    func loadNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            notificationStatus = "Not requested"
            notificationAdvice = "The app will ask for permission when you schedule a follow-up."
        case .denied:
            notificationStatus = "Off"
            notificationAdvice = "Allow notifications in iOS Settings to receive follow-up reminders."
        case .authorized:
            notificationStatus = "Allowed"
            notificationAdvice = "You can change alert and sound options in iOS Settings."
        case .provisional:
            notificationStatus = "Quiet delivery"
            notificationAdvice = "Reminders are delivered quietly. You can change this in iOS Settings."
        case .ephemeral:
            notificationStatus = "Temporary permission"
            notificationAdvice = "Notification permission is temporary. Check iOS Settings for available options."
        @unknown default:
            notificationStatus = "Unknown"
            notificationAdvice = "Check notification permission in iOS Settings."
        }
    }
}
