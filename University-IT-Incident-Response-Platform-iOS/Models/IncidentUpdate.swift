import Foundation

nonisolated struct IncidentUpdate: Identifiable, Equatable, Sendable {
    let id: UUID
    let incidentID: UUID
    let note: String
    let status: IncidentStatus
    let createdAt: Date

    init(
        id: UUID = UUID(),
        incidentID: UUID,
        note: String,
        status: IncidentStatus,
        createdAt: Date = Date()
    ) throws {
        let note = note.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !note.isEmpty else {
            throw IncidentValidationError.emptyUpdateNote
        }

        self.id = id
        self.incidentID = incidentID
        self.note = note
        self.status = status
        self.createdAt = createdAt
    }
}
