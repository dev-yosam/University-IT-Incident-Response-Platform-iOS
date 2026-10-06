import SwiftUI

struct UpdateIncidentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: UpdateIncidentViewModel
    @FocusState private var isNoteFocused: Bool

    init(model: UpdateIncidentViewModel) {
        _model = State(initialValue: model)
    }

    private var isResolution: Bool { model.mode == .resolution }

    var body: some View {
        @Bindable var model = model

        Form {
            if let error = model.errorMessage {
                Section { IncidentErrorView(message: error) }
            }
            Section {
                TextField(
                    isResolution ? "Describe how you fixed the problem" : "Describe your progress",
                    text: $model.note, axis: .vertical
                )
                .focused($isNoteFocused)
                .lineLimit(5...10)
                .accessibilityIdentifier("incidentNote")
            } header: {
                Text(isResolution ? "Resolution" : "Progress note")
            } footer: {
                if isResolution {
                    Text("Resolving this incident moves it to Resolved and clears its follow-up time.")
                }
            }
        }
        .disabled(model.isSaving)
        .navigationTitle(isResolution ? "Resolve Incident" : "Add Progress Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isNoteFocused = false }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .disabled(model.isSaving)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(model.isSaving ? "Saving…" : "Save") {
                    Task {
                        if await model.save() { dismiss() }
                    }
                }
                .disabled(model.isSaving)
            }
        }
        .interactiveDismissDisabled(model.isSaving)
    }
}
