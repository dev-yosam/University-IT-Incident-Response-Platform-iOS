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

    init(scope: GetIncidents.Scope, getIncidents: GetIncidents) {
        self.scope = scope
        self.getIncidents = getIncidents
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            incidents = try await getIncidents.execute(scope: scope)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
