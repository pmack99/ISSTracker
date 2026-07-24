import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("International Space Station Tracker")
                        .font(.title2.weight(.bold))

                    Text("Originally built by Preston Mack, Christine Deer, Sarah Sefcik, and Jennifer Gibson at UCF Coding Bootcamp. This iPhone version carries forward the same idea with native maps, location, and on-device history.")

                    Group {
                        Text("Data sources")
                            .font(.headline)
                        Label("Live position — Where The ISS At", systemImage: "antenna.radiowaves.left.and.right")
                        Label("Visible passes — N2YO", systemImage: "eye")
                        Label("Geocoding — Apple MapKit", systemImage: "mappin.and.ellipse")
                        Label("Photos — NASA Image and Video Library", systemImage: "photo")
                    }

                    Group {
                        Text("Improvements in this app")
                            .font(.headline)
                        Text("• Real altitude, speed, and visibility on the live map\n• “Use my location” for pass predictions\n• Local pass reminders before overhead flyovers\n• Lists every upcoming pass, not just one\n• Search history saved on your device (no shared Firebase log)\n• Correct N2YO API URLs (the web app’s host format was outdated)")
                    }
                }
                .padding()
            }
            .navigationTitle("About")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

#Preview {
    AboutView()
}
