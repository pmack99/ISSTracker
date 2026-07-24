import CoreLocation
import SwiftData
import SwiftUI

struct PassesView: View {
    @Environment(ISSTrackerStore.self) private var store
    @Environment(LocationManager.self) private var locationManager
    @Environment(PassNotificationService.self) private var passNotifications
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @Query(sort: \SavedLocation.createdAt, order: .reverse) private var savedLocations: [SavedLocation]

    private let leadTimeOptions = [5, 10, 15, 30]

    private var defaultSavedLocation: SavedLocation? {
        savedLocations.first(where: \.isDefaultLocation)
    }

    private var heroPlaceName: String? {
        store.lastSearchLabel ?? defaultSavedLocation?.name
    }

    private var tonightPass: ISSPass? {
        PassHighlightLogic.nextPassTonight(from: store.passes)
    }

    private var nextUpcomingPass: ISSPass? {
        PassHighlightLogic.nextUpcomingPass(from: store.passes)
    }

    var body: some View {
        @Bindable var notifications = passNotifications

        NavigationStack {
            List {
                TonightPassHeroCard(
                    placeName: heroPlaceName,
                    tonightPass: tonightPass,
                    nextUpcomingPass: nextUpcomingPass,
                    isLoading: store.isLoadingPasses,
                    hasDefaultSavedLocation: defaultSavedLocation != nil
                ) {
                    Task {
                        await store.refreshPassesForDefaultSavedLocation(
                            modelContext: modelContext,
                            notificationService: passNotifications
                        )
                    }
                }

                Section {
                    Toggle("Remind me before passes", isOn: $notifications.notificationsEnabled)
                        .onChange(of: passNotifications.notificationsEnabled) { _, enabled in
                            Task { await handleNotificationsToggled(enabled) }
                        }

                    if passNotifications.notificationsEnabled {
                        Picker("Notify", selection: $notifications.leadTimeMinutes) {
                            ForEach(leadTimeOptions, id: \.self) { minutes in
                                Text("\(minutes) minutes before").tag(minutes)
                            }
                        }
                        .onChange(of: passNotifications.leadTimeMinutes) { _, _ in
                            Task { await rescheduleNotificationsIfNeeded() }
                        }
                    }

                    if passNotifications.authorizationStatus == .denied {
                        Label("Notifications are off in Settings.", systemImage: "bell.slash")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if let summary = passNotifications.lastScheduleSummary {
                        Text(summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Alerts")
                } footer: {
                    Text("Reminders are scheduled after each successful pass search.")
                }

                Section {
                    TextField("City or zip code", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    Button {
                        Task { await searchByText() }
                    } label: {
                        Label("Search passes", systemImage: "magnifyingglass")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ISSTheme.accent)
                    .disabled(searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || store.isLoadingPasses)

                    Button {
                        locationManager.requestCurrentLocation()
                        Task { await searchFromDeviceLocation() }
                    } label: {
                        Label("Use my location", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.isLoadingPasses)

                    if let error = locationManager.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                } header: {
                    Text("Where to look")
                } footer: {
                    Text("Visible ISS passes for the next 10 days.")
                }

                SavedLocationsSection(
                    lastSearchLabel: store.lastSearchLabel,
                    lastLatitude: store.lastSearchLatitude,
                    lastLongitude: store.lastSearchLongitude
                ) { location in
                    Task {
                        await store.searchPasses(
                            placeName: location.name,
                            latitude: location.latitude,
                            longitude: location.longitude,
                            modelContext: modelContext,
                            notificationService: passNotifications
                        )
                    }
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
                        VStack(alignment: .leading, spacing: 10) {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                                .font(.subheadline)
                            if !searchText.isEmpty {
                                Button("Search again") {
                                    Task { await searchByText() }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }

                if let label = store.lastSearchLabel, !store.passes.isEmpty {
                    Section {
                        ForEach(store.passes) { pass in
                            NavigationLink {
                                PassDetailView(pass: pass, placeName: label)
                            } label: {
                                PassRow(pass: pass)
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    } header: {
                        Text("Passes for \(label)")
                    } footer: {
                        Text("\(store.passes.count) upcoming visible pass\(store.passes.count == 1 ? "" : "es")")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Overhead")
            .toolbarTitleDisplayMode(.inlineLarge)
            .task {
                await store.refreshPassesForDefaultSavedLocation(
                    modelContext: modelContext,
                    notificationService: passNotifications
                )
            }
        }
        .tint(ISSTheme.accent)
    }

    private func handleNotificationsToggled(_ enabled: Bool) async {
        if enabled {
            let granted = await passNotifications.requestAuthorization()
            if granted {
                await rescheduleNotificationsIfNeeded()
            }
        } else {
            passNotifications.cancelScheduledPasses()
        }
    }

    private func rescheduleNotificationsIfNeeded() async {
        guard passNotifications.notificationsEnabled,
              let label = store.lastSearchLabel,
              !store.passes.isEmpty
        else { return }
        await passNotifications.schedulePasses(store.passes, placeName: label)
    }

    private func searchByText() async {
        do {
            let result = try await locationManager.geocode(query: searchText)
            await store.searchPasses(
                placeName: result.name,
                latitude: result.coordinate.latitude,
                longitude: result.coordinate.longitude,
                modelContext: modelContext,
                notificationService: passNotifications
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
            modelContext: modelContext,
            notificationService: passNotifications
        )
    }
}

private struct PassRow: View {
    let pass: ISSPass

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(pass.startDate.formatted(date: .complete, time: .shortened))
                    .font(.headline)
                Spacer()
                Text(pass.startDate, format: .relative(presentation: .named))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(ISSTheme.accent)
            }

            HStack(spacing: 8) {
                miniStat("Duration", value: pass.durationFormatted, icon: "timer")
                miniStat("Max", value: String(format: "%.0f°", pass.maxEl), icon: "arrow.up.right")
                if let mag = pass.magnitude {
                    miniStat("Mag", value: String(format: "%.1f", mag), icon: "sparkles")
                }
            }

            HStack(spacing: 16) {
                Label(pass.startAzCompass, systemImage: "arrow.down.right.circle")
                Label(pass.endAzCompass, systemImage: "arrow.up.right.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func miniStat(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PassesView()
        .environment(ISSTrackerStore())
        .environment(LocationManager())
        .environment(PassNotificationService())
        .environment(HeadingManager())
}
