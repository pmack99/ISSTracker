import CoreLocation
import MapKit
import SwiftUI

struct LiveMapView: View {
    @Environment(ISSTrackerStore.self) private var store
    @AppStorage("liveMapFollowISS") private var followISS = true
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var mapSpan = MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    @State private var suppressCameraTracking = false
    @State private var expandedBottomPanel: LiveMapBottomPanel?

    var body: some View {
        NavigationStack {
            Group {
                if let position = store.position {
                    LiveMapTrackContent(
                        position: position,
                        motionPrevious: store.motionPreviousPosition,
                        followISS: $followISS,
                        cameraPosition: $cameraPosition,
                        mapSpan: $mapSpan,
                        suppressCameraTracking: $suppressCameraTracking,
                        expandedBottomPanel: $expandedBottomPanel,
                        crew: store.issCrew,
                        isLoadingCrew: store.isLoadingCrew,
                        crewError: store.crewError,
                        cabin: store.cabinTelemetry,
                        cabinStatusMessage: store.cabinStatusMessage,
                        onRetryCrew: { await store.refreshCrew() }
                    )
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
                            Task {
                                await store.refreshPosition()
                                await store.refreshCrew()
                            }
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
            .refreshable {
                await store.refreshPosition()
                await store.refreshCrew()
            }
            .onAppear {
                store.setLiveTabVisible(true)
                Task { await store.refreshCrew() }
            }
            .onDisappear { store.setLiveTabVisible(false) }
        }
        .tint(ISSTheme.accent)
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

/// Stable Map instance; only annotation coordinates update on a timer (not the whole Map view tree).
private struct LiveMapTrackContent: View {
    let position: ISSPosition
    let motionPrevious: ISSPosition?
    @Binding var followISS: Bool
    @Binding var cameraPosition: MapCameraPosition
    @Binding var mapSpan: MKCoordinateSpan
    @Binding var suppressCameraTracking: Bool
    @Binding var expandedBottomPanel: LiveMapBottomPanel?

    let crew: [SpaceTraveler]
    let isLoadingCrew: Bool
    let crewError: String?
    let cabin: ISSCabinTelemetry
    let cabinStatusMessage: String?
    var onRetryCrew: () async -> Void

    @State private var displayCoordinate: CLLocationCoordinate2D
    @State private var displayPosition: ISSPosition

    init(
        position: ISSPosition,
        motionPrevious: ISSPosition?,
        followISS: Binding<Bool>,
        cameraPosition: Binding<MapCameraPosition>,
        mapSpan: Binding<MKCoordinateSpan>,
        suppressCameraTracking: Binding<Bool>,
        expandedBottomPanel: Binding<LiveMapBottomPanel?>,
        crew: [SpaceTraveler],
        isLoadingCrew: Bool,
        crewError: String?,
        cabin: ISSCabinTelemetry,
        cabinStatusMessage: String?,
        onRetryCrew: @escaping () async -> Void
    ) {
        self.position = position
        self.motionPrevious = motionPrevious
        _followISS = followISS
        _cameraPosition = cameraPosition
        _mapSpan = mapSpan
        _suppressCameraTracking = suppressCameraTracking
        _expandedBottomPanel = expandedBottomPanel
        self.crew = crew
        self.isLoadingCrew = isLoadingCrew
        self.crewError = crewError
        self.cabin = cabin
        self.cabinStatusMessage = cabinStatusMessage
        self.onRetryCrew = onRetryCrew

        let initial = ISSMotionInterpolator.coordinate(
            at: .now,
            current: position,
            previous: motionPrevious
        )
        _displayCoordinate = State(initialValue: initial)
        _displayPosition = State(
            initialValue: ISSMotionInterpolator.displayPosition(
                at: .now,
                current: position,
                previous: motionPrevious
            )
        )
    }

    var body: some View {
        Map(position: $cameraPosition) {
            Annotation("", coordinate: displayCoordinate) {
                issMarker
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .overlay(alignment: .bottom) {
            LiveMapBottomDock(
                expandedPanel: $expandedBottomPanel,
                position: displayPosition,
                followISS: followISS,
                crew: crew,
                isLoadingCrew: isLoadingCrew,
                crewError: crewError,
                cabin: cabin,
                cabinStatusMessage: cabinStatusMessage,
                onRetryCrew: onRetryCrew
            )
        }
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
        .task(id: position.timestamp) {
            await runMotionLoop()
        }
        .onAppear {
            if followISS {
                recenterCamera(on: displayCoordinate)
            }
        }
        .onChange(of: position.timestamp) { _, _ in
            if followISS {
                let coordinate = ISSMotionInterpolator.coordinate(
                    at: .now,
                    current: position,
                    previous: motionPrevious
                )
                recenterCamera(on: coordinate)
            }
        }
    }

    private var issMarker: some View {
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

    private func runMotionLoop() async {
        let frameInterval = 1.0 / 15.0
        while !Task.isCancelled {
            let date = Date()
            displayCoordinate = ISSMotionInterpolator.coordinate(
                at: date,
                current: position,
                previous: motionPrevious
            )
            displayPosition = ISSMotionInterpolator.displayPosition(
                at: date,
                current: position,
                previous: motionPrevious
            )
            try? await Task.sleep(for: .seconds(frameInterval))
        }
    }

    private func recenterCamera(on coordinate: CLLocationCoordinate2D) {
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

#Preview {
    LiveMapView()
        .environment(ISSTrackerStore())
}
