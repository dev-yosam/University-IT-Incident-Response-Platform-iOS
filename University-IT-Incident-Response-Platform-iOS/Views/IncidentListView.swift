import SwiftUI

struct IncidentListView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: IncidentListViewModel
    @State private var isReporting = false
    let dependencies: AppDependencies

    init(model: IncidentListViewModel, dependencies: AppDependencies) {
        _model = State(initialValue: model)
        self.dependencies = dependencies
    }

    private var isActive: Bool { model.scope == .active }

    var body: some View {
        List {
            if let error = model.errorMessage {
                Section {
                    IncidentErrorView(message: error)
                    Button("Reload incidents") { Task { await model.load() } }
                }
            }
            if model.incidents.isEmpty {
                if model.isLoading {
                    ProgressView("Loading incidents…")
                } else if model.errorMessage == nil {
                    ContentUnavailableView {
                        Label(
                            isActive ? "No active incidents" : "No resolved incidents",
                            systemImage: isActive ? "wrench.and.screwdriver" : "checkmark.circle"
                        )
                    } description: {
                        Text(isActive
                             ? "Report a classroom equipment problem to start tracking your work."
                             : "Incidents appear here after you record a resolution.")
                    } actions: {
                        if isActive {
                            Button("Report incident") { isReporting = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                Section(isActive ? "Needs attention" : "Completed work") {
                    ForEach(model.incidents) { incident in
                        NavigationLink {
                            IncidentDetailView(
                                model: dependencies.makeIncidentDetail(id: incident.id),
                                dependencies: dependencies
                            )
                        } label: {
                            incidentRow(incident)
                        }
                    }
                }
            }
        }
        .navigationTitle(isActive ? "Active Incidents" : "Resolved Incidents")
        .toolbar {
            if isActive {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Report incident", systemImage: "plus") { isReporting = true }
                        .accessibilityIdentifier("reportIncident")
                }
            }
        }
        .refreshable { await model.load() }
        .task { await model.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.load() } }
        }
        .sheet(isPresented: $isReporting, onDismiss: {
            Task { await model.load() }
        }) {
            NavigationStack {
                ReportIncidentView(model: dependencies.makeReportIncident())
            }
        }
    }

    private func incidentRow(_ incident: Incident) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(incident.title)
                .font(.headline)
            Text(incident.details)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
            HStack {
                Text(incident.status.title)
                Text("·")
                Text("\(incident.priority.title) priority")
                    .foregroundStyle(incident.priority == .high ? Color.orange : Color.secondary)
            }
            .font(.caption)
            if isActive, let followUp = incident.followUpAt {
                Label {
                    Text("Follow-up: \(followUp.formatted(date: .abbreviated, time: .shortened))")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
            } else if let resolvedAt = incident.resolvedAt {
                Text("Resolved \(resolvedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
