import CoreLocation
import Foundation

/// Orbit motion math shared by the app map and dock.
enum ISSOrbitMotion {
    static func coordinate(
        at date: Date,
        latitude: Double,
        longitude: Double,
        timestamp: TimeInterval,
        velocity: Double,
        previousLatitude: Double?,
        previousLongitude: Double?,
        previousTimestamp: TimeInterval?
    ) -> (latitude: Double, longitude: Double) {
        let now = date.timeIntervalSince1970
        let currentPoint = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)

        if let previousLatitude, let previousLongitude, let previousTimestamp, previousTimestamp < timestamp {
            let span = timestamp - previousTimestamp
            let elapsed = now - previousTimestamp
            if span > 0, elapsed <= span {
                let fraction = elapsed / span
                let point = interpolate(
                    from: CLLocationCoordinate2D(latitude: previousLatitude, longitude: previousLongitude),
                    to: currentPoint,
                    fraction: fraction
                )
                return (point.latitude, point.longitude)
            }
        }

        let age = now - timestamp
        guard age > 0, velocity > 0 else { return (latitude, longitude) }

        let bearing = motionBearing(
            currentLatitude: latitude,
            currentLongitude: longitude,
            previousLatitude: previousLatitude,
            previousLongitude: previousLongitude
        )
        let distanceKm = velocity / 3600 * age
        let point = offset(from: currentPoint, bearingDegrees: bearing, distanceKm: distanceKm)
        return (point.latitude, point.longitude)
    }

    private static func motionBearing(
        currentLatitude: Double,
        currentLongitude: Double,
        previousLatitude: Double?,
        previousLongitude: Double?
    ) -> Double {
        if let previousLatitude, let previousLongitude {
            let from = CLLocationCoordinate2D(latitude: previousLatitude, longitude: previousLongitude)
            let to = CLLocationCoordinate2D(latitude: currentLatitude, longitude: currentLongitude)
            return initialBearing(from: from, to: to)
        }
        return 90
    }

    private static func interpolate(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, fraction: Double) -> CLLocationCoordinate2D {
        let t = min(max(fraction, 0), 1)
        if t <= 0 { return from }
        if t >= 1 { return to }
        let distance = haversineDistanceKm(from: from, to: to)
        guard distance > 0.001 else { return to }
        let bearing = initialBearing(from: from, to: to)
        return offset(from: from, bearingDegrees: bearing, distanceKm: distance * t)
    }

    private static func haversineDistanceKm(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let earthRadiusKm = 6371.0
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLat = (to.latitude - from.latitude) * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadiusKm * asin(min(1, sqrt(a)))
    }

    private static func initialBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180
        let lat2 = to.latitude * .pi / 180
        let dLon = (to.longitude - from.longitude) * .pi / 180
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        var bearing = atan2(y, x) * 180 / .pi
        if bearing < 0 { bearing += 360 }
        return bearing
    }

    private static func offset(from: CLLocationCoordinate2D, bearingDegrees: Double, distanceKm: Double) -> CLLocationCoordinate2D {
        let earthRadiusKm = 6371.0
        let bearing = bearingDegrees * .pi / 180
        let lat1 = from.latitude * .pi / 180
        let lon1 = from.longitude * .pi / 180
        let angularDistance = distanceKm / earthRadiusKm

        let lat2 = asin(sin(lat1) * cos(angularDistance) + cos(lat1) * sin(angularDistance) * cos(bearing))
        let lon2 = lon1 + atan2(
            sin(bearing) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2)
        )

        return CLLocationCoordinate2D(latitude: lat2 * 180 / .pi, longitude: lon2 * 180 / .pi)
    }
}
