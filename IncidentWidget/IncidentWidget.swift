import SwiftUI
import WidgetKit

struct IncidentWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedIncidentSnapshot?
    let errorMessage: String?

    static var preview: IncidentWidgetEntry {
        let date = Date()
        return IncidentWidgetEntry(
            date: date,
            snapshot: SharedIncidentSnapshot(generatedAt: date, activeIncidentCount: 2, incidents: [
                .init(id: UUID(), title: "Projector has no image", locationName: "Building 11 · Room 101",
                      status: .inProgress, priority: .high, followUpAt: date.addingTimeInterval(3600)),
                .init(id: UUID(), title: "Classroom display is offline", locationName: "Building 2 · Room 101",
                      status: .reported, priority: .normal, followUpAt: nil)
            ]),
            errorMessage: nil
        )
    }
}

struct IncidentTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> IncidentWidgetEntry { .preview }

    func getSnapshot(in context: Context, completion: @escaping (IncidentWidgetEntry) -> Void) {
        completion(context.isPreview ? .preview : readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<IncidentWidgetEntry>) -> Void) {
        let entry = readEntry()
        completion(Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(900))))
    }

    private func readEntry() -> IncidentWidgetEntry {
        do {
            return IncidentWidgetEntry(date: Date(), snapshot: try SharedIncidentStore.appGroup().read(), errorMessage: nil)
        } catch {
            return IncidentWidgetEntry(date: Date(), snapshot: nil, errorMessage: error.localizedDescription)
        }
    }
}

@main
struct IncidentWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedIncidentSnapshot.widgetKind, provider: IncidentTimelineProvider()) { entry in
            IncidentWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Campus IT Incidents")
        .description("See active incidents and the next follow-up while working around campus.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    IncidentWidget()
} timeline: {
    IncidentWidgetEntry.preview
}

#Preview(as: .systemMedium) {
    IncidentWidget()
} timeline: {
    IncidentWidgetEntry.preview
}
