import Foundation
import Observation

@MainActor
@Observable
final class UpdateIncidentViewModel {
    enum Mode {
        case progressNote
        case resolution
    }

    let incidentID: UUID
    let mode: Mode
    var note = ""
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    private(set) var savedIncident: Incident?

    private let addUpdate: AddIncidentUpdate
    private let resolveIncident: ResolveIncident

    init(
        incidentID: UUID,
        mode: Mode,
        addUpdate: AddIncidentUpdate,
        resolveIncident: ResolveIncident
    ) {
        self.incidentID = incidentID
        self.mode = mode
        self.addUpdate = addUpdate
        self.resolveIncident = resolveIncident
    }

    func save() async -> Bool {
        guard !isSaving, savedIncident == nil else { return false }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            switch mode {
            case .progressNote:
                savedIncident = try await addUpdate.execute(incidentID: incidentID, note: note)
            case .resolution:
                savedIncident = try await resolveIncident.execute(incidentID: incidentID, resolution: note)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
