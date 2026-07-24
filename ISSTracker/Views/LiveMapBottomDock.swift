import SwiftUI

enum LiveMapBottomPanel: Equatable {
    case live
    case crew
    case cabin
}

private enum DockMetricStyle {
    case orbit
    case cabin
}

struct LiveMapBottomDock: View {
    @Binding var expandedPanel: LiveMapBottomPanel?
    let position: ISSPosition?
    let followISS: Bool
    let crew: [SpaceTraveler]
    let isLoadingCrew: Bool
    let crewError: String?
    let cabin: ISSCabinTelemetry
    let cabinStatusMessage: String?
    var onRetryCrew: () async -> Void

    private let tabBarHeight: CGFloat = 56
    private let cornerRadius: CGFloat = 14
    private let expandAnimation: Animation = .smooth(duration: 0.38)

    var body: some View {
        VStack(spacing: 0) {
            if let expandedPanel {
                expandedContent(for: expandedPanel)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .bottom)))
                    .id(expandedPanel)
            }

            tabBar
                .frame(height: tabBarHeight)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .animation(expandAnimation, value: expandedPanel)
    }

    @ViewBuilder
    private func expandedContent(for panel: LiveMapBottomPanel) -> some View {
        switch panel {
        case .live:
            if let position {
                ISSLiveOrbitContent(position: position, followISS: followISS, enlarged: true)
            } else {
                Text("Waiting for orbit data…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .crew:
            ISSCrewListContent(
                crew: crew,
                isLoading: isLoadingCrew,
                errorMessage: crewError,
                retry: { Task { await onRetryCrew() } },
                twoColumnDock: true
            )
        case .cabin:
            ISSCabinLiveContent(telemetry: cabin, statusMessage: cabinStatusMessage, enlarged: true)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            tab(panel: .live, title: "LIVE", systemImage: "dot.radiowaves.left.and.right")
            tab(panel: .crew, title: "CREW", systemImage: "person.2.fill")
            tab(panel: .cabin, title: "CABIN", systemImage: "house.fill")
        }
    }

    private func tab(panel: LiveMapBottomPanel, title: String, systemImage: String) -> some View {
        let isSelected = expandedPanel == panel

        return Button {
            expandedPanel = expandedPanel == panel ? nil : panel
        } label: {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.5)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(isSelected ? ISSTheme.accent : Color.secondary)
            .background(
                isSelected ? ISSTheme.accent.opacity(0.18) : Color.clear,
                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? ISSTheme.accent.opacity(0.35) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Expanded panel content

struct ISSLiveOrbitContent: View {
    let position: ISSPosition
    let followISS: Bool
    var enlarged: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: enlarged ? 10 : 6) {
            HStack(spacing: 8) {
                Text("Orbit")
                    .font(enlarged ? .headline : .caption.weight(.semibold))
                Spacer()
                ISSStatusBadge(text: position.visibilityLabel, tint: visibilityTint)
            }

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: enlarged ? 12 : 6) {
                    dockMetric(
                        title: "Latitude",
                        value: String(format: "%.4f°", position.latitude),
                        icon: "lines.measurement.horizontal",
                        style: .orbit
                    )
                    dockMetric(
                        title: "Altitude",
                        value: String(format: "%.0f km", position.altitude),
                        icon: "arrow.up.and.down",
                        style: .orbit
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: enlarged ? 12 : 6) {
                    dockMetric(
                        title: "Longitude",
                        value: String(format: "%.4f°", position.longitude),
                        icon: "lines.measurement.vertical",
                        style: .orbit
                    )
                    dockMetric(
                        title: "Speed",
                        value: String(format: "%.0f km/h", position.velocity),
                        icon: "speedometer",
                        style: .orbit
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(followISS ? "Follow ISS on · pan map to turn off" : "Follow ISS off")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var visibilityTint: Color {
        position.visibility.lowercased() == "daylight" ? .yellow : .cyan
    }
}

struct ISSCabinLiveContent: View {
    let telemetry: ISSCabinTelemetry
    let statusMessage: String?
    var enlarged: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Inside the station")
                    .font(.headline)
                Spacer()
                Text("NASA · Lightstreamer")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let statusMessage, !telemetry.hasAnyValue {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if !telemetry.hasAnyValue {
                Text("Waiting for cabin telemetry…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(metricPairs.enumerated()), id: \.offset) { _, pair in
                        HStack(alignment: .top, spacing: 14) {
                            if let left = pair.0 {
                                cabinMetric(left)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                            if let right = pair.1 {
                                cabinMetric(right)
                            } else {
                                Color.clear.frame(maxWidth: .infinity)
                            }
                        }
                    }
                }

                if let updated = telemetry.lastUpdated {
                    Text("Updated \(updated.formatted(date: .omitted, time: .standard))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private struct CabinMetric: Identifiable {
        let id = UUID()
        let title: String
        let value: String
        let icon: String
    }

    private var metricPairs: [(CabinMetric?, CabinMetric?)] {
        var items: [CabinMetric] = []
        if let v = telemetry.cabinPressure {
            items.append(CabinMetric(title: "Pressure", value: v, icon: "gauge"))
        }
        if let v = telemetry.cabinTemperature {
            items.append(CabinMetric(title: "Temperature", value: v, icon: "thermometer.medium"))
        }
        if let v = telemetry.cabinCO2 {
            items.append(CabinMetric(title: "CO₂", value: v, icon: "aqi.medium"))
        }
        if let v = telemetry.urineTankQuantity {
            items.append(CabinMetric(title: "Urine tank", value: v, icon: "drop.fill"))
        }
        if let v = telemetry.wasteWaterQuantity {
            items.append(CabinMetric(title: "Waste water", value: v, icon: "drop.triangle.fill"))
        }
        if let v = telemetry.cleanWaterQuantity {
            items.append(CabinMetric(title: "Clean water", value: v, icon: "drop.circle.fill"))
        }

        var pairs: [(CabinMetric?, CabinMetric?)] = []
        var index = items.startIndex
        while index < items.endIndex {
            let left = items[index]
            index = items.index(after: index)
            let right = index < items.endIndex ? items[index] : nil
            if right != nil { index = items.index(after: index) }
            pairs.append((left, right))
        }
        return pairs
    }

    private func cabinMetric(_ metric: CabinMetric) -> some View {
        dockMetric(title: metric.title, value: metric.value, icon: metric.icon, style: .cabin)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

typealias ISSLiveTelemetryContent = ISSLiveOrbitContent

struct ISSCrewListContent: View {
    let crew: [SpaceTraveler]
    let isLoading: Bool
    let errorMessage: String?
    var retry: (() -> Void)?
    var compact: Bool = false
    var twoColumnDock: Bool = false

    private var dockTitle: String {
        twoColumnDock ? "On Board the ISS" : "On board"
    }

    private let dockColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: twoColumnDock ? 10 : (compact ? 6 : 10)) {
            HStack {
                Text(dockTitle)
                    .font(twoColumnDock ? .headline : .caption.weight(.semibold))
                Spacer()
                if isLoading, crew.isEmpty {
                    ProgressView()
                        .controlSize(twoColumnDock ? .small : .mini)
                } else if !crew.isEmpty {
                    ISSStatusBadge(text: "\(crew.count)", tint: ISSTheme.accent)
                }
            }

            if !compact, !twoColumnDock {
                Text("Open Notify")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let errorMessage, crew.isEmpty {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let retry {
                    Button("Retry", action: retry)
                        .font(.subheadline.weight(.semibold))
                }
            } else if crew.isEmpty, !isLoading {
                Text("No ISS crew listed.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if twoColumnDock {
                ScrollView {
                    LazyVGrid(columns: dockColumns, alignment: .leading, spacing: 10) {
                        ForEach(crew) { traveler in
                            Text(traveler.name)
                                .font(.subheadline.weight(.medium))
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 160)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: compact ? 4 : 8) {
                        ForEach(crew) { traveler in
                            Text(traveler.name)
                                .font(compact ? .caption : .subheadline)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxHeight: compact ? 100 : 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared metric styling

private func dockMetric(title: String, value: String, icon: String, style: DockMetricStyle) -> some View {
    VStack(alignment: .leading, spacing: style == .cabin ? 4 : 6) {
        Label(title, systemImage: icon)
            .font(style == .cabin ? .caption.weight(.medium) : .subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
        Text(value)
            .font(style == .cabin ? .subheadline.weight(.semibold) : .title3.weight(.semibold))
            .monospacedDigit()
            .minimumScaleFactor(0.8)
            .lineLimit(style == .cabin ? 3 : 2)
    }
}
