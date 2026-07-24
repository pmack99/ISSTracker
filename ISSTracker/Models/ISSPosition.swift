import Foundation

struct ISSPosition: Codable, Equatable {
    let name: String
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let velocity: Double
    let visibility: String
    let timestamp: TimeInterval

    var coordinate: (lat: Double, lon: Double) { (latitude, longitude) }

    var updatedAt: Date { Date(timeIntervalSince1970: timestamp) }

    var visibilityLabel: String {
        switch visibility.lowercased() {
        case "daylight": "Daylight"
        case "eclipsed": "Earth's shadow"
        default: visibility.capitalized
        }
    }
}
