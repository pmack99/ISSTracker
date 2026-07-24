import SwiftUI

struct AboutView: View {
    private let webRepoURL = URL(string: "https://github.com/pmack99/Brandnew_ISS_Tracker")!
    private let iosRepoURL = URL(string: "https://github.com/pmack99/ISSTracker")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("International Space Station Tracker", systemImage: "globe.americas.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(ISSTheme.accent)

                        Text("Originally built by Preston Mack, Christine Deer, Sarah Sefcik, and Jennifer Gibson at UCF Coding Bootcamp. This iPhone app continues the project with native maps, location, reminders, and on-device history.")
                            .foregroundStyle(.secondary)
                    }
                    .issGroupedCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data sources")
                            .font(.headline)
                        sourceRow("Live position", detail: "Where The ISS At", icon: "antenna.radiowaves.left.and.right")
                        sourceRow("Visible passes", detail: "N2YO", icon: "eye")
                        sourceRow("Geocoding", detail: "Apple MapKit", icon: "mappin.and.ellipse")
                        sourceRow("Photos", detail: "NASA Image and Video Library", icon: "photo")
                    }
                    .issGroupedCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Project links")
                            .font(.headline)
                        Link(destination: iosRepoURL) {
                            Label("iOS app on GitHub", systemImage: "iphone")
                        }
                        Link(destination: webRepoURL) {
                            Label("Original web app on GitHub", systemImage: "safari")
                        }
                    }
                    .issGroupedCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("License")
                            .font(.headline)
                        Text("This project uses the same MIT License as the original ISS Tracker web repository (Start Bootstrap / Blackrock Digital LLC, 2013–2018).")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        NavigationLink {
                            LicenseView()
                        } label: {
                            Label("View MIT License", systemImage: "doc.text")
                        }
                    }
                    .issGroupedCard()
                }
                .padding()
            }
            .issScreenBackground()
            .navigationTitle("About")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
        .tint(ISSTheme.accent)
    }

    private func sourceRow(_ title: String, detail: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(ISSTheme.accent)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AboutView()
}
