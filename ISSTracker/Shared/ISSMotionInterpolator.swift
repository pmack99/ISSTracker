import CoreLocation
import Foundation

enum ISSMotionInterpolator {
    static func coordinate(at date: Date, current: ISSPosition, previous: ISSPosition?) -> CLLocationCoordinate2D {
        let pair = ISSOrbitMotion.coordinate(
            at: date,
            latitude: current.latitude,
            longitude: current.longitude,
            timestamp: current.timestamp,
            velocity: current.velocity,
            previousLatitude: previous?.latitude,
            previousLongitude: previous?.longitude,
            previousTimestamp: previous?.timestamp
        )
        return CLLocationCoordinate2D(latitude: pair.latitude, longitude: pair.longitude)
    }

    static func displayPosition(at date: Date, current: ISSPosition, previous: ISSPosition?) -> ISSPosition {
        let coordinate = coordinate(at: date, current: current, previous: previous)
        return ISSPosition(
            name: current.name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            altitude: current.altitude,
            velocity: current.velocity,
            visibility: current.visibility,
            timestamp: current.timestamp
        )
    }
}
