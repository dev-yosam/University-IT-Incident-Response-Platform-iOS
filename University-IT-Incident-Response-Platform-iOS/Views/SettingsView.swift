import SwiftUI
import UIKit

struct SettingsView: View {
    @AppStorage("appAppearance") private var appearance: AppAppearance = .system
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = SettingsViewModel()

    var body: some View {
        Form {
            Section {
                Picker("Theme", selection: $appearance) {
                    ForEach(AppAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
            } header: {
                Text("Appearance")
            } footer: {
                Text("System follows your device appearance. This choice applies to the app.")
            }

            Section {
                LabeledContent("Permission", value: model.notificationStatus)
                Link("Open iOS Settings", destination: URL(string: UIApplication.openSettingsURLString)!)
            } header: {
                Text("Notifications")
            } footer: {
                Text(model.notificationAdvice)
            }

            Section("About") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Campus IT Incidents")
                        .font(.headline)
                    Text("Record campus IT issues and track follow-up work.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Version", value: model.version)
                Text("Incident records are stored on this device. They are not synced between devices.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
        .task { await model.loadNotificationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model.loadNotificationStatus() }
            }
        }
    }
}
