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
                    ProgressView("Fetching ISS position…")
                } else {
                    ContentUnavailableView(
                        "No position yet",
                        systemImage: "antenna.radiowaves.left.and.right.slash",
                        description: Text(store.positionError ?? "Pull to refresh.")
                    )
                }
            }
            .navigationTitle("ISS Live")
            .toolbarTitleDisplayMode(.inlineLarge)
            .refreshable { await store.refreshPosition() }
            .safeAreaInset(edge: .bottom) {
                if let position = store.position {
                    ISSMetricsCard(position: position)
                        .padding()
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
    }

    @ViewBuilder
    private func mapContent(for position: ISSPosition) -> some View {
        Map(position: $cameraPosition) {
            Annotation("ISS", coordinate: CLLocationCoordinate2D(latitude: position.latitude, longitude: position.longitude)) {
                Image("ISSMarker")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .shadow(radius: 4)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Updated \(position.updatedAt.formatted(date: .abbreviated, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    metric("Latitude", value: String(format: "%.4f°", position.latitude))
                    metric("Longitude", value: String(format: "%.4f°", position.longitude))
                }
                GridRow {
                    metric("Altitude", value: String(format: "%.0f km", position.altitude))
                    metric("Speed", value: String(format: "%.0f km/h", position.velocity))
                }
                GridRow {
                    metric("Visibility", value: position.visibilityLabel)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
    }
}

#Preview {
    LiveMapView()
        .environment(ISSTrackerStore())
}
