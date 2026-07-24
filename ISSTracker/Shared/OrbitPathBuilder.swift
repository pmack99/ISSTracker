import CoreLocation
import Foundation

struct N2YOOrbitResponse: Decodable {
    struct OrbitPoint: Decodable {
        let satlatitude: Double
        let satlongitude: Double
    }

    let positions: [OrbitPoint]
}

enum OrbitPathBuilder {
    static let defaultForwardSeconds = 300
    static let stepDistanceKm = 90.0

    static func coordinates(from response: N2YOOrbitResponse) -> [CLLocationCoordinate2D] {
        response.positions.map {
            CLLocationCoordinate2D(latitude: $0.satlatitude, longitude: $0.satlongitude)
        }
    }

    static func forwardPath(
        current: ISSPosition,
        previous: ISSPosition?,
        forwardFromAPI: [CLLocationCoordinate2D]?
    ) -> [CLLocationCoordinate2D] {
        if let forwardFromAPI, forwardFromAPI.count >= 2 {
            return forwardFromAPI
        }
        return extrapolatedForward(from: current, previous: previous)
    }

    static func endBearing(for path: [CLLocationCoordinate2D]) -> Double {
        guard path.count >= 2 else { return 0 }
        return initialBearing(from: path[path.count - 2], to: path[path.count - 1])
    }

    static func extrapolatedForward(from current: ISSPosition, previous: ISSPosition?, steps: Int = 34, stepDistanceKm: Double = stepDistanceKm) -> [CLLocationCoordinate2D] {
        let start = CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude)
        let bearing = travelBearing(current: current, previous: previous)

        var path = [start]
        var point = start
        for _ in 0 ..< steps {
            point = coordinate(from: point, bearingDegrees: bearing, distanceKm: stepDistanceKm)
            path.append(point)
        }
        return path
    }

    private static func travelBearing(current: ISSPosition, previous: ISSPosition?) -> Double {
        if let previous {
            let prior = CLLocationCoordinate2D(latitude: previous.latitude, longitude: previous.longitude)
            let here = CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude)
            return initialBearing(from: prior, to: here)
        }
        return 90
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

    private static func coordinate(from: CLLocationCoordinate2D, bearingDegrees: Double, distanceKm: Double) -> CLLocationCoordinate2D {
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
