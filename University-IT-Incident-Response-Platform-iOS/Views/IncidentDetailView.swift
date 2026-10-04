import SwiftUI

struct IncidentDetailView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: IncidentDetailViewModel
    @State private var followUpDate = Date().addingTimeInterval(3600)
    @State private var isUpdating = false
    @State private var updateMode: UpdateIncidentViewModel.Mode = .progressNote
    let dependencies: AppDependencies

    init(model: IncidentDetailViewModel, dependencies: AppDependencies) {
        _model = State(initialValue: model)
        self.dependencies = dependencies
    }

    var body: some View {
        List {
            if let error = model.errorMessage {
                Section {
                    IncidentErrorView(message: error)
                    Button("Reload incident") { Task { await model.load() } }
                }
            }
            if let incident = model.incident {
                incidentSummary(incident)
                if incident.status != .resolved {
                    responseActions(incident)
                    followUpSection(incident)
                }
                historySection
            } else if model.isLoading {
                ProgressView("Loading incident…")
            }
        }
        .disabled(model.isSaving)
        .navigationTitle("Incident Details")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await model.load() }
        .task { await model.load() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.load() } }
        }
        .onChange(of: model.incident?.followUpAt) { _, date in
            if let date { followUpDate = date }
        }
        .sheet(isPresented: $isUpdating, onDismiss: {
            Task { await model.load() }
        }) {
            NavigationStack {
                UpdateIncidentView(
                    model: dependencies.makeIncidentUpdate(id: model.incidentID, mode: updateMode)
                )
            }
        }
    }

    private func incidentSummary(_ incident: Incident) -> some View {
        Section {
            Text(incident.title).font(.title2.bold())
            Text(incident.details)
            if let location = model.location {
                Label(location.displayName, systemImage: "building.2")
            }
            LabeledContent("Status", value: incident.status.title)
            LabeledContent("Priority", value: incident.priority.title)
            LabeledContent("Reported") {
                Text(incident.createdAt, format: .dateTime.day().month().year().hour().minute())
            }
            if let resolvedAt = incident.resolvedAt {
                LabeledContent("Resolved") {
                    Text(resolvedAt, format: .dateTime.day().month().year().hour().minute())
                }
            }
        }
    }

    private func responseActions(_ incident: Incident) -> some View {
        Section("Response") {
            if incident.status == .reported {
                Button("Start response", systemImage: "wrench.and.screwdriver") {
                    Task { await model.startWork() }
                }
            }
            Button("Add progress note", systemImage: "square.and.pencil") {
                updateMode = .progressNote
                isUpdating = true
            }
            if incident.status == .inProgress {
                Button("Resolve incident", systemImage: "checkmark.circle") {
                    updateMode = .resolution
                    isUpdating = true
                }
            }
        }
        .disabled(model.isLoading)
    }

    private func followUpSection(_ incident: Incident) -> some View {
        Section {
            if let date = incident.followUpAt {
                LabeledContent("Scheduled") {
                    Text(date, format: .dateTime.day().month().hour().minute())
                }
            }
            DatePicker("Check again", selection: $followUpDate, displayedComponents: [.date, .hourAndMinute])
            Button(incident.followUpAt == nil ? "Schedule follow-up" : "Update follow-up") {
                Task { await model.scheduleFollowUp(at: followUpDate) }
            }
        } header: {
            Text("Follow-up")
        } footer: {
            Text("Save a time to check this incident again. It will appear in the active incident list.")
        }
        .disabled(model.isLoading)
    }

    private var historySection: some View {
        Section("Response history") {
            if model.updates.isEmpty {
                Text("No progress notes yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(model.updates) { update in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(update.note)
                        Text(update.status.title)
                            .font(.caption)
                        Text(update.createdAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}
