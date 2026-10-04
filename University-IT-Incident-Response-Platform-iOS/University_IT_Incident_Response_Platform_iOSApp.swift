//
//  University_IT_Incident_Response_Platform_iOSApp.swift
//  University-IT-Incident-Response-Platform-iOS
//
//  Created by yosam on 2/10/2026.
//

import SwiftUI

@main
struct University_IT_Incident_Response_Platform_iOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var dependencies: AppDependencies?
    @State private var startupError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let dependencies {
                    ContentView(dependencies: dependencies)
                } else if let startupError {
                    ContentUnavailableView {
                        Label("Incident records unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(startupError)
                    } actions: {
                        Button("Try again") {
                            Task { await loadIncidents() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ProgressView("Opening incident records…")
                }
            }
            .safeAreaInset(edge: .top) {
                if let dependencies, let error = dependencies.widgetErrorMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(error)
                        Button("Refresh widget summary") {
                            Task { await dependencies.refreshWidget() }
                        }
                    }
                    .font(.footnote)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                }
            }
            .task { await loadIncidents() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, let dependencies {
                    Task { await dependencies.refreshWidget() }
                }
            }
        }
    }

    private func loadIncidents() async {
        guard dependencies == nil else { return }
        startupError = nil
        do {
            dependencies = try await AppDependencies.load()
        } catch {
            startupError = "Your incident records could not be opened. Try again to access your saved work."
        }
    }
}
