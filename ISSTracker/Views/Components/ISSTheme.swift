import SwiftUI

enum ISSTheme {
    static let accent = Color(red: 0.95, green: 0.55, blue: 0.22)
    /// Live map ISS callout — distinct from MapKit city labels.
    static let liveMapISS = Color(red: 0.92, green: 0.12, blue: 0.18)
    static let spaceDeep = Color(red: 0.05, green: 0.08, blue: 0.16)

    static var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.10, blue: 0.20),
                Color(red: 0.02, green: 0.03, blue: 0.08),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension View {
    func issGroupedCard() -> some View {
        padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    func issScreenBackground() -> some View {
        background(Color(.systemGroupedBackground))
    }
}

struct ISSLoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .issScreenBackground()
    }
}

struct ISSErrorStateView: View {
    let title: String
    let message: String
    let systemImage: String
    var retryTitle: String = "Try Again"
    var retry: (() async -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button(retryTitle) {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
                .tint(ISSTheme.accent)
            }
        }
        .issScreenBackground()
    }
}

struct ISSStatusBadge: View {
    let text: String
    var tint: Color = ISSTheme.accent

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(tint.opacity(0.18), in: Capsule())
            .foregroundStyle(tint)
    }
}
