import SwiftUI
import WidgetKit

struct NextPassEntry: TimelineEntry {
    let date: Date
    let snapshot: SharedPassSnapshot?
}

struct NextPassProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextPassEntry {
        NextPassEntry(date: .now, snapshot: sampleSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextPassEntry) -> Void) {
        completion(NextPassEntry(date: .now, snapshot: SharedPassStorage.load() ?? sampleSnapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextPassEntry>) -> Void) {
        let snapshot = SharedPassStorage.load()
        let entry = NextPassEntry(date: .now, snapshot: snapshot)
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now.addingTimeInterval(900)
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private var sampleSnapshot: SharedPassSnapshot {
        SharedPassSnapshot(
            placeName: "Orlando, FL",
            startUTC: Date().addingTimeInterval(7200).timeIntervalSince1970,
            endUTC: Date().addingTimeInterval(7500).timeIntervalSince1970,
            startAzCompass: "NNW",
            maxEl: 42,
            updatedAt: Date().timeIntervalSince1970
        )
    }
}

struct NextPassWidgetView: View {
    let entry: NextPassEntry

    var body: some View {
        Group {
            if let snapshot = entry.snapshot {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                        Text("Next ISS pass")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.secondary)

                    Text(snapshot.placeName)
                        .font(.headline)
                        .lineLimit(1)

                    if Date() >= snapshot.startDate, Date() <= snapshot.endDate {
                        Text("Visible now")
                            .font(.title3.weight(.bold))
                        Text("Ends \(snapshot.endDate, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(snapshot.startDate, style: .relative)
                            .font(.title3.weight(.bold))
                        Text("\(snapshot.startDate.formatted(date: .abbreviated, time: .shortened)) · \(snapshot.startAzCompass)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ISS Tracker")
                        .font(.headline)
                    Text("Save a starred place in the app and search passes to show a countdown here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.10, blue: 0.20),
                    Color(red: 0.02, green: 0.03, blue: 0.08),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct NextPassWidget: Widget {
    let kind = "NextPassWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextPassProvider()) { entry in
            NextPassWidgetView(entry: entry)
        }
        .configurationDisplayName("Next ISS Pass")
        .description("Countdown to the next visible pass for your starred saved place.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    NextPassWidget()
} timeline: {
    NextPassEntry(date: .now, snapshot: nil)
}
