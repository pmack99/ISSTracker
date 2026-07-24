import SwiftData
import SwiftUI

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PassSearchRecord.searchedAt, order: .reverse) private var records: [PassSearchRecord]

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        "No searches yet",
                        systemImage: "clock",
                        description: Text("Pass lookups you run will appear here on this device.")
                    )
                } else {
                    List(records) { record in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.placeName)
                                .font(.headline)
                            Text(record.passStart.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                            Text("Departs \(record.departsTo) · \(record.durationSeconds)s · max \(String(format: "%.0f°", record.maxElevation))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
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
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: PassSearchRecord.self, inMemory: true)
}
