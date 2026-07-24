import SwiftUI

@main
struct ISSTrackerApp: App {
    @State private var store = ISSTrackerStore()
    @State private var locationManager = LocationManager()
    @State private var passNotifications = PassNotificationService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(locationManager)
                .environment(passNotifications)
                .task { await passNotifications.refreshAuthorizationStatus() }
        }
        .modelContainer(for: PassSearchRecord.self)
    }
}
