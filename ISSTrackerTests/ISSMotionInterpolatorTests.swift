import CoreLocation
import Foundation
import Testing
@testable import ISSTracker

struct ISSMotionInterpolatorTests {
    private func position(
        lat: Double,
        lon: Double,
        timestamp: TimeInterval,
        velocity: Double = 27_600
    ) -> ISSPosition {
        ISSPosition(
            name: "iss",
            latitude: lat,
            longitude: lon,
            altitude: 420,
            velocity: velocity,
            visibility: "daylight",
            timestamp: timestamp
        )
    }

    @Test func displayPositionMatchesCoordinateAtSameInstant() {
        let t0: TimeInterval = 1_700_000_000
        let previous = position(lat: 10, lon: 20, timestamp: t0)
        let current = position(lat: 11, lon: 21, timestamp: t0 + 30)
        let sample = Date(timeIntervalSince1970: t0 + 15)

        let coordinate = ISSMotionInterpolator.coordinate(at: sample, current: current, previous: previous)
        let display = ISSMotionInterpolator.displayPosition(at: sample, current: current, previous: previous)

        #expect(abs(display.latitude - coordinate.latitude) < 0.0001)
        #expect(abs(display.longitude - coordinate.longitude) < 0.0001)
        #expect(display.altitude == current.altitude)
        #expect(display.velocity == current.velocity)
    }
}
