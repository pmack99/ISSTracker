import CoreLocation
import Foundation

@MainActor
@Observable
final class HeadingManager: NSObject {
    var headingDegrees: Double?
    var accuracy: CLLocationDirection?
    var errorMessage: String?

    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.headingFilter = 2
    }

    func start() {
        errorMessage = nil
        guard CLLocationManager.headingAvailable() else {
            errorMessage = "Compass is not available on this device."
            return
        }
        manager.startUpdatingHeading()
    }

    func stop() {
        manager.stopUpdatingHeading()
    }
}

extension HeadingManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let value = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        Task { @MainActor in
            headingDegrees = value
            accuracy = newHeading.headingAccuracy
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            errorMessage = error.localizedDescription
        }
    }
}
