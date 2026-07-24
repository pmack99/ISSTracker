import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PassSearchRecord.searchedAt, order: .reverse) private var records: [PassSearchRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView {
                        Label("No searches yet", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Pass lookups you run on the Overhead tab will appear here on this device.")
                    }
                    .issScreenBackground()
                } else {
                    List {
                        ForEach(records) { record in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(record.placeName, systemImage: "mappin.and.ellipse")
                                        .font(.headline)
                                    Spacer()
                                    Text(record.passStart, format: .relative(presentation: .named))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Text(record.passStart.formatted(date: .abbreviated, time: .shortened))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 12) {
                                    Label(record.appearsFrom, systemImage: "location.north.line")
                                    Label("\(Int(record.maxElevation))°", systemImage: "arrow.up.right")
                                    Label(formatDuration(record.durationSeconds), systemImage: "timer")
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                if !records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear", role: .destructive) {
                            records.forEach { modelContext.delete($0) }
                        }
                    }
                }
            }
        }
        .tint(ISSTheme.accent)
    }

    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        if minutes > 0 { return "\(minutes)m \(remainder)s" }
        return "\(remainder)s"
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: PassSearchRecord.self, inMemory: true)
}
