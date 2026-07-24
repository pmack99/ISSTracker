import CoreLocation
import SwiftData
import SwiftUI

struct PassesView: View {
    @Environment(ISSTrackerStore.self) private var store
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("City or zip code", text: $searchText)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()

                        Button("Search") {
                            Task { await searchByText() }
                        }
                        .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoadingPasses)
                    }

                    Button {
                        locationManager.requestCurrentLocation()
                        Task { await searchFromDeviceLocation() }
                    } label: {
                        Label("Use my location", systemImage: "location.fill")
                    }
                    .disabled(store.isLoadingPasses)

                    if let error = locationManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Where to look")
                } footer: {
                    Text("Shows visible ISS passes for the next 10 days (N2YO).")
                }

                if store.isLoadingPasses {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView("Loading passes…")
                            Spacer()
                        }
                    }
                }

                if let error = store.passesError {
                    Section {
                        Text(error)
                            .foregroundStyle(.secondary)
                    }
                }

                if let label = store.lastSearchLabel, !store.passes.isEmpty {
                    Section("Passes for \(label)") {
                        ForEach(store.passes) { pass in
                            PassRow(pass: pass)
                        }
                    }
                }
            }
            .navigationTitle("Overhead")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }

    private func searchByText() async {
        do {
            let result = try await locationManager.geocode(query: searchText)
            await store.searchPasses(
                placeName: result.name,
                latitude: result.coordinate.latitude,
                longitude: result.coordinate.longitude,
                modelContext: modelContext
            )
        } catch {
            store.passesError = "Could not find that location. Try a city and state or zip code."
        }
    }

    private func searchFromDeviceLocation() async {
        if let location = locationManager.lastLocation {
            await runSearch(at: location)
            return
        }
        try? await Task.sleep(for: .milliseconds(800))
        if let location = locationManager.lastLocation {
            await runSearch(at: location)
        } else if locationManager.errorMessage == nil {
            store.passesError = "Waiting for location… try again in a moment."
        }
    }

    private func runSearch(at location: CLLocation) async {
        let name = locationManager.lastPlaceName ?? "Your location"
        await store.searchPasses(
            placeName: name,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            modelContext: modelContext
        )
    }
}

private struct PassRow: View {
    let pass: ISSPass

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(pass.startDate.formatted(date: .complete, time: .shortened))
                .font(.headline)

            LabeledContent("Duration", value: pass.durationFormatted)
            LabeledContent("Appears", value: pass.startAzCompass)
            LabeledContent("Max elevation", value: String(format: "%.1f°", pass.maxEl))
            LabeledContent("Departs", value: pass.endAzCompass)

            if let mag = pass.magnitude {
                LabeledContent("Brightness", value: String(format: "%.1f mag", mag))
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    PassesView()
        .environment(ISSTrackerStore())
        .environment(LocationManager())
}
