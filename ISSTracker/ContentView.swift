import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            LiveMapView()
                .tabItem {
                    Label("Live", systemImage: "globe.americas.fill")
                }

            PassesView()
                .tabItem {
                    Label("Passes", systemImage: "arrow.down.circle.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            GalleryView()
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
    }
}

#Preview {
    ContentView()
        .environment(ISSTrackerStore())
        .environment(LocationManager())
}
