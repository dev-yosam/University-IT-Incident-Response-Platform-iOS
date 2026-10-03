import Foundation
import Testing
@testable import University_IT_Incident_Response_Platform_iOS

struct DomainModelTests {
    @Test func newIncidentTrimsTextAndStartsAsReported() throws {
        let locationID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_800_000_000)

        let incident = try Incident(
            title: "  Projector has no image\n",
            details: "\nThe projector turns on but shows a blank screen.  ",
            locationID: locationID,
            createdAt: createdAt
        )

        #expect(incident.title == "Projector has no image")
        #expect(incident.details == "The projector turns on but shows a blank screen.")
        #expect(incident.locationID == locationID)
        #expect(incident.status == .reported)
        #expect(incident.priority == .normal)
        #expect(incident.createdAt == createdAt)
        #expect(incident.updatedAt == createdAt)
        #expect(incident.followUpAt == nil)
        #expect(incident.resolvedAt == nil)
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func incidentRejectsBlankTitle(title: String) {
        #expect(throws: IncidentValidationError.emptyTitle) {
            try Incident(
                title: title,
                details: "The projector shows a blank screen.",
                locationID: UUID()
            )
        }
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func incidentRejectsBlankDetails(details: String) {
        #expect(throws: IncidentValidationError.emptyDetails) {
            try Incident(
                title: "Projector has no image",
                details: details,
                locationID: UUID()
            )
        }
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func incidentUpdateRejectsBlankNote(note: String) {
        #expect(throws: IncidentValidationError.emptyUpdateNote) {
            try IncidentUpdate(
                incidentID: UUID(),
                note: note,
                status: .inProgress
            )
        }
    }

    @Test func incidentUpdateKeepsItsIncidentAndStatusWhenTrimmingNote() throws {
        let incidentID = UUID()
        let update = try IncidentUpdate(
            incidentID: incidentID,
            note: "  Replaced the display cable.\n",
            status: .inProgress
        )

        #expect(update.incidentID == incidentID)
        #expect(update.status == .inProgress)
        #expect(update.note == "Replaced the display cable.")
    }

    @Test(arguments: [
        (" \n", "Building 11", "Room 101", IncidentValidationError.emptyCampus),
        ("UTS", "\t", "Room 101", IncidentValidationError.emptyBuilding),
        ("UTS", "Building 2", "", IncidentValidationError.emptyRoom)
    ])
    func campusLocationRequiresCampusBuildingAndRoom(
        campus: String,
        building: String,
        room: String,
        expectedError: IncidentValidationError
    ) {
        #expect(throws: expectedError) {
            try CampusLocation(campus: campus, building: building, room: room)
        }
    }

    @Test func campusLocationTrimsNames() throws {
        let location = try CampusLocation(
            campus: "  UTS\n",
            building: " Building 8 ",
            room: "\tRoom 101 "
        )

        #expect(location.campus == "UTS")
        #expect(location.building == "Building 8")
        #expect(location.room == "Room 101")
    }
}
