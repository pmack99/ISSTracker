import MapKit
import SwiftUI

struct LiveMapView: View {
    @Environment(ISSTrackerStore.self) private var store
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            Group {
                if let position = store.position {
                    mapContent(for: position)
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
                    ISSMetricsCard(position: position)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .onAppear {
                store.startLiveUpdates()
                if let position = store.position {
                    center(on: position)
                }
            }
            .onDisappear { store.stopLiveUpdates() }
            .onChange(of: store.position) { _, newValue in
                if let newValue { center(on: newValue) }
            }
        }
        .tint(ISSTheme.accent)
    }

    @ViewBuilder
    private func mapContent(for position: ISSPosition) -> some View {
        Map(position: $cameraPosition) {
            Annotation("ISS", coordinate: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)) {
                Image("ISSMarker")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                    .shadow(color: ISSTheme.accent.opacity(0.45), radius: 8)
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
    }

    private func center(on position: ISSPosition) {
        cameraPosition = .region(
            MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude),
                span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
            )
        )
    }
}

private struct ISSMetricsCard: View {
    let position: ISSPosition

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
