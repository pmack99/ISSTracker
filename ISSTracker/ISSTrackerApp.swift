import SwiftUI

@main
struct ISSTrackerApp: App {
    @State private var store = ISSTrackerStore()
    @State private var locationManager = LocationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(locationManager)
        }
        .modelContainer(for: PassSearchRecord.self)
    }
}
