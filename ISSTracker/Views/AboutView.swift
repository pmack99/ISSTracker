import SwiftUI

struct AboutView: View {
    private let supportURL = URL(string: "https://3pmstudios.github.io/ISSTracker/support.html")!
    private let privacyURL = URL(string: "https://3pmstudios.github.io/ISSTracker/privacy.html")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("International Space Station Tracker", systemImage: "globe.americas.fill")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(ISSTheme.accent)

                        Text("Originally developed as a group project in the University of Central Florida Coding Bootcamp. This iPhone app is published by 3PM Studios with native maps, location, reminders, and on-device history.")
                            .foregroundStyle(.secondary)
                    }
                    .issGroupedCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Data sources")
                            .font(.headline)
                        sourceRow("Live position", detail: "Where The ISS At", icon: "antenna.radiowaves.left.and.right")
                        sourceRow("Crew on board", detail: "Open Notify", icon: "person.2")
                        sourceRow("Cabin environment", detail: "NASA ISSLIVE · Lightstreamer", icon: "house")
                        sourceRow("Visible passes", detail: "Pollux ISS Pass API", icon: "eye")
                        sourceRow("Geocoding", detail: "Apple MapKit", icon: "mappin.and.ellipse")
                        sourceRow("Photos", detail: "NASA Image and Video Library", icon: "photo")
                    }
                    .issGroupedCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Support")
                            .font(.headline)
                        Link(destination: supportURL) {
                            Label("Help & FAQ", systemImage: "questionmark.circle")
                        }
                        Link(destination: privacyURL) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                        Link(destination: URL(string: "mailto:3PMStudios@protonmail.com")!) {
                            Label("3PMStudios@protonmail.com", systemImage: "envelope")
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
