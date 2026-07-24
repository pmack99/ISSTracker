import SwiftUI

struct TonightPassHeroCard: View {
    let placeName: String?
    let tonightPass: ISSPass?
    let nextUpcomingPass: ISSPass?
    let isLoading: Bool
    let hasPrimarySavedLocation: Bool
    var onRefreshPrimary: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Label("Tonight’s pass", systemImage: "moon.stars.fill")
                    .font(.headline)
                    .foregroundStyle(ISSTheme.accent)

                if isLoading, placeName == nil {
                    ProgressView("Loading passes…")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let placeName, let tonightPass {
                    heroPassContent(pass: tonightPass, placeName: placeName, headline: "Visible tonight")
                } else if let placeName, let nextUpcomingPass {
                    Text("No pass left tonight for \(placeName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    heroPassContent(
                        pass: nextUpcomingPass,
                        placeName: placeName,
                        headline: "Next up"
                    )
                } else if hasPrimarySavedLocation {
                    Text("Couldn’t load passes for your starred location. Check your connection and try again.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Refresh starred location", action: onRefreshPrimary)
                        .buttonStyle(.bordered)
                        .tint(ISSTheme.accent)
                } else {
                    Text("Star a saved place to see tonight’s pass here and use it as your default for reminders.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        } footer: {
            if let placeName {
                Text("Based on passes for \(placeName). Search below for another location.")
            } else {
                Text("Uses your starred saved place when you set one.")
            }
        }
    }

    @ViewBuilder
    private func heroPassContent(pass: ISSPass, placeName: String, headline: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(headline)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            NavigationLink {
                PassDetailView(pass: pass, placeName: placeName)
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(pass.startDate.formatted(date: .complete, time: .shortened))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    HStack(spacing: 12) {
                        Label(String(format: "%.0f° max", pass.maxEl), systemImage: "arrow.up.right")
                        Label(pass.startAzCompass, systemImage: "location.north.line")
                        Text(pass.durationFormatted)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    Text(pass.startDate, format: .relative(presentation: .named))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ISSTheme.accent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}
