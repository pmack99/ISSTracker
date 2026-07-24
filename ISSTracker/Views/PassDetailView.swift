import SwiftUI

struct PassDetailView: View {
    let pass: ISSPass
    let placeName: String

    @Environment(HeadingManager.self) private var headingManager
    @State private var trackLiveActivity = true

    private var targetDegrees: Double? {
        CompassAzimuth.degrees(for: pass.startAzCompass)
    }

    var body: some View {
        List {
            Section("Pass") {
                LabeledContent("Location", value: placeName)
                LabeledContent("Starts", value: pass.startDate.formatted(date: .complete, time: .shortened))
                LabeledContent("Ends", value: pass.endDate.formatted(date: .complete, time: .shortened))
                LabeledContent("Duration", value: pass.durationFormatted)
                LabeledContent("Max elevation", value: String(format: "%.1f°", pass.maxEl))
            }

            Section {
                if let targetDegrees {
                    CompassAssistView(
                        targetDegrees: targetDegrees,
                        compassLabel: pass.startAzCompass,
                        deviceHeading: headingManager.headingDegrees
                    )
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)

                    if let heading = headingManager.headingDegrees {
                        Text(CompassAzimuth.turnInstruction(deviceHeading: heading, targetDegrees: targetDegrees))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Text("Hold phone flat and rotate slowly to calibrate the compass.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    Text("Could not map direction \(pass.startAzCompass) to a compass bearing.")
                        .foregroundStyle(.secondary)
                }

                if let error = headingManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            } header: {
                Text("Look \(pass.startAzCompass)")
            } footer: {
                Text("Compass assist uses your iPhone magnetometer. Simulators do not provide real heading data.")
            }

            Section {
                Toggle("Track this pass live", isOn: $trackLiveActivity)
                    .onChange(of: trackLiveActivity) { _, enabled in
                        let snapshot = SharedPassSnapshot(
                            placeName: placeName,
                            startUTC: pass.startUTC,
                            endUTC: pass.endUTC,
                            startAzCompass: pass.startAzCompass,
                            maxEl: pass.maxEl,
                            updatedAt: Date().timeIntervalSince1970
                        )
                        if enabled {
                            WidgetPassSyncService.publish(snapshot: snapshot)
                            PassLiveActivityManager.sync(with: snapshot)
                        } else {
                            PassLiveActivityManager.endAll()
                        }
                    }
            } header: {
                Text("Dynamic Island")
            } footer: {
                Text("Shows a Live Activity during the pass window while the system allows it. Works best on a physical iPhone.")
            }
        }
        .navigationTitle("Pass detail")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { headingManager.start() }
        .onDisappear { headingManager.stop() }
        .tint(ISSTheme.accent)
    }
}

private struct CompassAssistView: View {
    let targetDegrees: Double
    let compassLabel: String
    let deviceHeading: Double?

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(.quaternary, lineWidth: 2)
                .background(Circle().fill(.ultraThinMaterial))

            Text("N")
                .font(.caption.weight(.bold))
                .offset(y: -88)

            if let deviceHeading {
                Image(systemName: "location.north.fill")
                    .font(.title2)
                    .foregroundStyle(ISSTheme.accent)
                    .rotationEffect(.degrees(deviceHeading - targetDegrees))
            }

            VStack(spacing: 4) {
                Text(compassLabel)
                    .font(.title2.weight(.bold))
                Text("ISS appears")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 200, height: 200)
        .padding(.vertical, 8)
    }
}

#Preview {
    NavigationStack {
        PassDetailView(
            pass: ISSPass(
                from: ISSPassResponse.Pass(
                    startUTC: Date().timeIntervalSince1970 + 3600,
                    endUTC: Date().timeIntervalSince1970 + 3900,
                    duration: 300,
                    startAzCompass: "NNW",
                    endAzCompass: "E",
                    startEl: 10,
                    maxEl: 45,
                    mag: -1.2
                )
            ),
            placeName: "Orlando, FL"
        )
    }
    .environment(HeadingManager())
}
