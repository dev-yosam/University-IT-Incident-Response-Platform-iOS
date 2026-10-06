University IT Incident Response Platform

This SwiftUI helps campus IT field support staff record classroom equipment problems, track their work, and plan follow-up checks.

Who the app is for

The app is designed for a staff member who moves between classrooms to check projectors, displays, and other teaching equipment. Each incident keeps the location, priority, status, and progress notes together. A reminder helps the staff member return to an issue that still needs attention.

The sample locations use UTS Building 2, Building 8, and Building 11. Each building uses Room 101 as a fictional example. The sample rooms are not an official room directory.

Using the app

Start by reporting an incident with a title, description, location, and priority. Open its details and select Start response when work begins. Add progress notes as you check the equipment, and set a follow-up time if another check is needed.

When the problem is fixed, enter a resolution. The incident moves from Active to Resolved, and its follow-up time and reminders are cleared. Its history remains available in the Resolved tab.

The main screens are Active Incidents, Report Incident, Incident Details, the progress note or resolution form, and Resolved Incidents.

Architecture

The app uses MVVM with a Use Case layer and repository protocols. A View calls its ViewModel. The ViewModel calls a Use Case, which works through a repository protocol. The Core Data repository implements that protocol and handles database access. Views and ViewModels do not call Core Data directly.

The Models folder contains Incident, IncidentUpdate, CampusLocation, and their related enums and validation errors. The UseCases folder contains operations such as ReportIncident, StartIncidentResponse, AddIncidentUpdate, ScheduleIncidentFollowUp, and ResolveIncident. These operations enforce business rules and define typed errors that explain what went wrong and what the user can do next.

Repositories contains the protocols and mock repositories used in unit tests. Persistence contains the Core Data model, entities, and repository implementations. ViewModels manages screen state, and Views contains the SwiftUI screens. Shared, Widgets, and Notifications contain the code for the shared summary and reminders.

AppDependencies connects these parts. After an incident is saved, the app updates the widget summary and synchronizes its reminders.

Database

Core Data stores incident records on the device. This suits a staff member who needs to record work without a network connection. The app supports one person's local workflow and does not use a server or CloudKit sync.

There are three related entities. CampusLocationEntity has many incidents. IncidentEntity belongs to one location and has many updates. IncidentUpdateEntity belongs to one incident and stores a note, status, and time.

Repository queries separate reported and in-progress incidents from resolved incidents. They also support finding open incidents with a follow-up time before a given deadline. Records remain after closing and reopening the app. The app does not provide backup or restore after app removal.

Home Screen widget

The IncidentWidget extension supports small and medium widgets. It shows the active incident count and a summary with the location and follow-up time. Staff can check this information from the Home Screen while moving between classrooms.

The main app writes incident-summary.json to an App Group container and calls WidgetCenter.reloadTimelines after relevant saves. The widget reads this summary. The Core Data store stays in the main app's container.

The App Group identifier is:

group.com.dev-yosam.University-IT-Incident-Response-Platform-iOS

This identifier must match the main app and widget entitlements, as well as SharedIncidentStore.appGroupID.

Notification Content Extension

The IncidentNotification extension displays a custom view for the INCIDENT_FOLLOW_UP notification category. It shows the incident title, building and room, priority, and follow-up time. This gives staff the details they need when a reminder arrives. The Open app button returns them to the app.

The main app schedules local notifications after permission is granted. The extension reads incident details from the notification payload. Changing a follow-up time updates the reminder, and resolving an incident removes it. Up to 60 upcoming reminders are scheduled at a time.

Setup

Development and simulator checks used Xcode 26.2 and an iPhone 17 Pro simulator with iOS 26.2. The project's minimum iOS version is 26.2.

Open University-IT-Incident-Response-Platform-iOS.xcodeproj in Xcode. Select the University-IT-Incident-Response-Platform-iOS scheme and an iOS 26.2 simulator. Press Command-R to build and run the main app. Both extensions are included in the build.

Sample campus locations are added on the first launch. Report an incident to create your first record.

To run on a physical device, configure signing for the main app, IncidentWidget, and IncidentNotification targets with your development team. Use bundle identifiers and an App Group registered to that team. If the App Group changes, update both entitlements and SharedIncidentStore.appGroupID together. Physical device testing has not been completed.

Trying the extensions

Open the app and create an active incident. Add Campus IT Incidents from the Home Screen widget gallery, then try the small and medium sizes.

In Incident Details, set a follow-up time a few minutes ahead and allow notifications when asked. Return to the Home Screen and wait for the reminder. Expand it to see the custom view. In the simulator, you can also swipe left on the notification and choose View.

Select Open app and resolve the incident. Check that it appears in Resolved and is removed from the widget's active summary.

If notifications are off, use Open Settings in the app's reminder message to enable them. If the widget has no summary yet, open the app first. Use Refresh widget summary if the app reports a shared summary error.

Testing

Select the main app scheme and an iOS simulator. In Xcode's Test navigator, run the University-IT-Incident-Response-Platform-iOSTests target.

The unit tests use mock repositories to check Use Cases and repository behavior. They cover reporting incidents, starting work, progress notes, resolution, follow-up dates, queries, and domain validation. Error cases include blank input, a follow-up time that is not in the future, and a failed save.

For a manual check, report an incident, add a progress note, and set a follow-up. Close and reopen the app to check that the data remains. Resolve the incident and check its history in the Resolved tab.
