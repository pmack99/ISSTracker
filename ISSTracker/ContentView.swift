import SwiftUI

struct ContentView: View {
    @Environment(ISSTrackerStore.self) private var store
    @State private var selectedTab: AppTab = .live

    var body: some View {
        TabView(selection: $selectedTab) {
            LiveMapView()
                .tag(AppTab.live)
                .tabItem {
                    Label("Live", systemImage: "globe.americas.fill")
                }

            PassesView()
                .tag(AppTab.passes)
                .tabItem {
                    Label("Passes", systemImage: "arrow.down.circle.fill")
                }

            HistoryView()
                .tag(AppTab.history)
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }

            GalleryView()
                .tag(AppTab.gallery)
                .tabItem {
                    Label("Photos", systemImage: "photo.on.rectangle.angled")
                }

            AboutView()
                .tag(AppTab.about)
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .tint(ISSTheme.accent)
        .onAppear {
            store.setLiveTabVisible(selectedTab == .live)
        }
        .onChange(of: selectedTab) { _, tab in
            store.setLiveTabVisible(tab == .live)
        }
    }
}

#Preview {
    ContentView()
        .environment(ISSTrackerStore())
        .environment(LocationManager())
        .environment(PassNotificationService())
}
