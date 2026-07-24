import SwiftUI

@main
struct ISSTrackerApp: App {
    @Environment(\.scenePhase) private var scenePhase

    @State private var store = ISSTrackerStore()
    @State private var locationManager = LocationManager()
    @State private var passNotifications = PassNotificationService()
    @State private var headingManager = HeadingManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(locationManager)
                .environment(passNotifications)
                .environment(headingManager)
                .task { await passNotifications.refreshAuthorizationStatus() }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        PassLiveActivityManager.sync(with: SharedPassStorage.load())
                    }
                }
        }
        .modelContainer(for: [PassSearchRecord.self, SavedLocation.self])
    }
}
