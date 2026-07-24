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
    static func coordinates(from response: N2YOOrbitResponse) -> [CLLocationCoordinate2D] {
        response.positions.map {
            CLLocationCoordinate2D(latitude: $0.satlatitude, longitude: $0.satlongitude)
        }
    }

    static func extrapolatedForward(from current: ISSPosition, previous: ISSPosition?, steps: Int = 24, stepDistanceKm: Double = 90) -> [CLLocationCoordinate2D] {
        let start = CLLocationCoordinate2D(latitude: current.latitude, longitude: current.longitude)
        let bearing: Double
        if let previous {
            let prior = CLLocationCoordinate2D(latitude: previous.latitude, longitude: previous.longitude)
            bearing = initialBearing(from: prior, to: start)
        } else {
            bearing = 90
        }

        var path = [start]
        var point = start
        for _ in 0 ..< steps {
            point = coordinate(from: point, bearingDegrees: bearing, distanceKm: stepDistanceKm)
            path.append(point)
        }
        return path
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
