import Foundation
import Observation

@MainActor
@Observable
final class IncidentListViewModel {
    let scope: GetIncidents.Scope
    private(set) var incidents: [Incident] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let getIncidents: GetIncidents
    private var reloadRequested = false

    init(scope: GetIncidents.Scope, getIncidents: GetIncidents) {
        self.scope = scope
        self.getIncidents = getIncidents
    }

    func load() async {
        reloadRequested = true
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        repeat {
            reloadRequested = false
            do {
                let latest = try await getIncidents.execute(scope: scope)
                // A refresh requested during this read needs a newer result.
                if reloadRequested { continue }
                incidents = latest
                errorMessage = nil
            } catch {
                if reloadRequested { continue }
                errorMessage = error.localizedDescription
            }
        } while reloadRequested
    }
}
