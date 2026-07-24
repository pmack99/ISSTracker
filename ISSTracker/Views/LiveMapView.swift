import CoreLocation
import MapKit
import SwiftUI

struct LiveMapView: View {
    @Environment(ISSTrackerStore.self) private var store
    @AppStorage("liveMapFollowISS") private var followISS = true
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapSpan = MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    @State private var suppressCameraTracking = false

    var body: some View {
        NavigationStack {
            Group {
                if let position = store.position {
                    TimelineView(.animation(minimumInterval: 1.0 / 15.0)) { timeline in
                        let displayCoordinate = ISSMotionInterpolator.coordinate(
                            at: timeline.date,
                            current: position,
                            previous: store.motionPreviousPosition
                        )
                        mapContent(for: position, displayCoordinate: displayCoordinate)
                    }
                } else if store.isLoadingPosition {
                    ISSLoadingView(message: "Fetching ISS position…")
                } else {
                    ISSErrorStateView(
                        title: "Can’t reach the station",
                        message: store.positionError ?? "Check your connection and try again.",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        retry: { await store.refreshPosition() }
                    )
                }
            }
            .navigationTitle("ISS Live")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        followISS.toggle()
                        if followISS, let position = store.position {
                            let coordinate = ISSMotionInterpolator.coordinate(
                                at: .now,
                                current: position,
                                previous: store.motionPreviousPosition
                            )
                            recenter(on: coordinate)
                        }
                    } label: {
                        Label(
                            "Follow ISS",
                            systemImage: followISS ? "location.fill" : "location"
                        )
                    }
                    .accessibilityHint(followISS ? "Map stays centered on the station." : "Map stays where you pan it.")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if store.isLoadingPosition, store.position != nil {
                        ProgressView()
                    } else {
                        Button {
                            Task { await store.refreshPosition() }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable { await store.refreshPosition() }
            .safeAreaInset(edge: .bottom) {
                if let position = store.position {
                    ISSMetricsCard(position: position, followISS: followISS)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .onAppear {
                store.startLiveUpdates()
                if followISS, let position = store.position {
                    let coordinate = ISSMotionInterpolator.coordinate(
                        at: .now,
                        current: position,
                        previous: store.motionPreviousPosition
                    )
                    recenter(on: coordinate)
                }
            }
            .onDisappear { store.stopLiveUpdates() }
            .onChange(of: store.position) { _, newValue in
                guard followISS, let newValue else { return }
                let coordinate = ISSMotionInterpolator.coordinate(
                    at: .now,
                    current: newValue,
                    previous: store.motionPreviousPosition
                )
                recenter(on: coordinate)
            }
        }
        .tint(ISSTheme.accent)
    }

    @ViewBuilder
    private func mapContent(
        for position: ISSPosition,
        displayCoordinate: CLLocationCoordinate2D
    ) -> some View {
        Map(position: $cameraPosition) {
            Annotation("", coordinate: displayCoordinate) {
                VStack(spacing: 4) {
                    Image("ISSMarker")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .shadow(color: ISSTheme.liveMapISS.opacity(0.55), radius: 10)
                        .overlay {
                            Circle()
                                .strokeBorder(ISSTheme.liveMapISS, lineWidth: 2.5)
                                .frame(width: 52, height: 52)
                        }

                    Text("ISS")
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(ISSTheme.liveMapISS)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.92), in: Capsule())
                        .overlay(Capsule().strokeBorder(ISSTheme.liveMapISS, lineWidth: 1.5))
                        .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .onMapCameraChange(frequency: .continuous) { context in
            mapSpan = context.region.span
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            guard followISS, !suppressCameraTracking else { return }
            let mapCenter = context.region.center
            let latDelta = abs(mapCenter.latitude - displayCoordinate.latitude)
            let lonDelta = abs(mapCenter.longitude - displayCoordinate.longitude)
            let span = context.region.span
            let movedFromFollow =
                latDelta > max(1.5, span.latitudeDelta * 0.08)
                || lonDelta > max(1.5, span.longitudeDelta * 0.08)
            if movedFromFollow {
                followISS = false
            }
        }
    }

    private func recenter(on coordinate: CLLocationCoordinate2D) {
        suppressCameraTracking = true
        cameraPosition = .region(
            MKCoordinateRegion(center: coordinate, span: mapSpan)
        )
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(400))
            suppressCameraTracking = false
        }
    }
}

private struct ISSMetricsCard: View {
    let position: ISSPosition
    let followISS: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Live telemetry")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                ISSStatusBadge(text: position.visibilityLabel, tint: visibilityTint)
            }

            Text("Updated \(position.updatedAt.formatted(date: .abbreviated, time: .standard)) · refreshes every 30s")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(followISS
                ? "Marker glides between updates · Follow ISS re-centers on each refresh (pan or pinch to turn off)."
                : "Marker glides between updates · Follow ISS is off.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    metric("Latitude", value: String(format: "%.4f°", position.latitude), icon: "lines.measurement.horizontal")
                    metric("Longitude", value: String(format: "%.4f°", position.longitude), icon: "lines.measurement.vertical")
                }
                GridRow {
                    metric("Altitude", value: String(format: "%.0f km", position.altitude), icon: "arrow.up.and.down")
                    metric("Speed", value: String(format: "%.0f km/h", position.velocity), icon: "speedometer")
                }
            }
        }
        .issGroupedCard()
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }

    private var visibilityTint: Color {
        position.visibility.lowercased() == "daylight" ? .yellow : .cyan
    }

    private func metric(_ title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
    }
}

#Preview {
    LiveMapView()
        .environment(ISSTrackerStore())
}
