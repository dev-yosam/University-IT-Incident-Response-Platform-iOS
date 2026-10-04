import SwiftUI
import WidgetKit

struct IncidentWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: IncidentWidgetEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            if family == .systemMedium {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("UTS IT").font(.caption.bold())
                        Text("\(snapshot.activeIncidentCount)").font(.largeTitle.bold()).foregroundStyle(.blue)
                        Text("active incidents").font(.caption)
                        Spacer(minLength: 0)
                        Text("Updated \(snapshot.generatedAt.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    .frame(width: 90, alignment: .leading)
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        if snapshot.incidents.isEmpty {
                            emptyMessage
                        } else {
                            ForEach(snapshot.incidents.prefix(2)) { incident in
                                incidentSummary(incident)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("UTS IT").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("\(snapshot.activeIncidentCount) active").font(.title2.bold()).foregroundStyle(.blue)
                    if let incident = snapshot.incidents.first {
                        incidentSummary(incident)
                    } else {
                        emptyMessage
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Label("Campus IT", systemImage: "wrench.and.screwdriver").font(.headline)
                Text(entry.errorMessage ?? "Open the incident app to load your campus incidents.")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var emptyMessage: some View {
        Text("No active incidents. Open the app to report an equipment problem.")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private func incidentSummary(_ incident: SharedIncidentSnapshot.IncidentSummary) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(incident.title).font(.caption.bold()).lineLimit(family == .systemSmall ? 2 : 1)
            Text(incident.locationName).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            if let followUp = incident.followUpAt {
                Text("Check \(followUp.formatted(.dateTime.day().month().hour().minute()))")
                    .font(.caption2)
                    .foregroundStyle(followUp <= entry.date ? Color.orange : Color.secondary)
                    .lineLimit(1)
            } else {
                Text(incident.status == .inProgress ? "In progress" : "Reported")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }
}
