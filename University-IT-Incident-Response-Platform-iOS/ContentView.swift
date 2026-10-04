//
//  ContentView.swift
//  University-IT-Incident-Response-Platform-iOS
//
//  Created by yosam on 2/10/2026.
//

import SwiftUI

struct ContentView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            Tab("Active", systemImage: "wrench.and.screwdriver") {
                NavigationStack {
                    IncidentListView(
                        model: dependencies.makeIncidentList(scope: .active), dependencies: dependencies
                    )
                }
            }
            Tab("Resolved", systemImage: "checkmark.circle") {
                NavigationStack {
                    IncidentListView(
                        model: dependencies.makeIncidentList(scope: .resolved), dependencies: dependencies
                    )
                }
            }
        }
    }
}
