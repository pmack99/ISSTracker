import SwiftData
import SwiftUI

struct SavedLocationsSection: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedLocation.createdAt, order: .reverse) private var savedLocations: [SavedLocation]

    var lastSearchLabel: String?
    var lastLatitude: Double?
    var lastLongitude: Double?
    var onSelect: (SavedLocation) -> Void

    var body: some View {
        Section {
            if savedLocations.isEmpty {
                Text("Save places for quick pass lookups. Star one as your default for reminders and Live Activity.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(savedLocations) { location in
                Button {
                    onSelect(location)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(location.name)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(String(format: "%.4f°, %.4f°", location.latitude, location.longitude))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if location.isDefaultLocation {
                            Image(systemName: "star.fill")
                                .foregroundStyle(ISSTheme.accent)
                                .accessibilityLabel("Default pass location")
                        }
                    }
                }

                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        modelContext.delete(location)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        setDefaultLocation(location)
                    } label: {
                        Label("Default", systemImage: "star")
                    }
                    .tint(ISSTheme.accent)
                }
            }

            if let lastSearchLabel, let lastLatitude, let lastLongitude {
                Button {
                    saveLocation(name: lastSearchLabel, latitude: lastLatitude, longitude: lastLongitude)
                } label: {
                    Label("Save “\(lastSearchLabel)”", systemImage: "bookmark.fill")
                }
            }
        } header: {
            Text("Saved places")
        } footer: {
            Text("Star a saved place for pass reminders and Live Activity when you search from the app.")
        }
    }

    private func saveLocation(name: String, latitude: Double, longitude: Double) {
        let isFirst = savedLocations.isEmpty
        let location = SavedLocation(
            name: name,
            latitude: latitude,
            longitude: longitude,
            isDefaultLocation: isFirst
        )
        modelContext.insert(location)
        try? modelContext.save()
    }

    private func setDefaultLocation(_ location: SavedLocation) {
        for item in savedLocations {
            item.isDefaultLocation = item.persistentModelID == location.persistentModelID
        }
        try? modelContext.save()
    }
}
