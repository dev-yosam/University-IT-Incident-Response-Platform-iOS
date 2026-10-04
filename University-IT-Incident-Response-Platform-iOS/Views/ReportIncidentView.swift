import SwiftUI

struct ReportIncidentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: ReportIncidentViewModel

    init(model: ReportIncidentViewModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        @Bindable var model = model

        Form {
            if let error = model.errorMessage {
                Section { IncidentErrorView(message: error) }
            }
            Section("Equipment problem") {
                TextField("Incident title", text: $model.title)
                    .accessibilityIdentifier("incidentTitle")
                TextField("Describe what is not working", text: $model.details, axis: .vertical)
                    .lineLimit(4...8)
                    .accessibilityIdentifier("incidentDetails")
            }
            Section("Campus location") {
                if model.isLoading {
                    ProgressView("Loading campus locations…")
                } else if model.locations.isEmpty {
                    Button("Reload campus locations") { Task { await model.loadLocations() } }
                } else {
                    Picker("Location", selection: $model.selectedLocationID) {
                        Text("Choose a location").tag(nil as UUID?)
                        ForEach(model.locations) { location in
                            Text(location.displayName).tag(Optional(location.id))
                        }
                    }
                    .accessibilityIdentifier("incidentLocation")
                }
            }
            Section("Urgency") {
                Picker("Priority", selection: $model.priority) {
                    ForEach(IncidentPriority.allCases, id: \.self) { priority in
                        Text(priority.title).tag(priority)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .disabled(model.isSaving)
        .navigationTitle("Report Incident")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(model.isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(model.isSaving ? "Reporting…" : "Report") {
                    Task {
                        if await model.submit() { dismiss() }
                    }
                }
                .disabled(model.isLoading || model.isSaving || model.locations.isEmpty)
            }
        }
        .interactiveDismissDisabled(model.isSaving)
        .task { await model.loadLocations() }
    }
}
