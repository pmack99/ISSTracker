import Foundation

enum CompassAzimuth {
    private static let compassToDegrees: [String: Double] = [
        "N": 0, "NNE": 22.5, "NE": 45, "ENE": 67.5,
        "E": 90, "ESE": 112.5, "SE": 135, "SSE": 157.5,
        "S": 180, "SSW": 202.5, "SW": 225, "WSW": 247.5,
        "W": 270, "WNW": 292.5, "NW": 315, "NNW": 337.5,
    ]

    static func degrees(for compass: String) -> Double? {
        compassToDegrees[compass.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()]
    }

    static func label(for degrees: Double) -> String {
        let labels = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        var bearing = degrees.truncatingRemainder(dividingBy: 360)
        if bearing < 0 { bearing += 360 }
        let index = Int((bearing + 11.25) / 22.5) % labels.count
        return labels[index]
    }

    static func turnInstruction(deviceHeading: Double, targetDegrees: Double) -> String {
        let delta = normalizedDelta(from: deviceHeading, to: targetDegrees)
        if abs(delta) <= 8 { return "You're facing the right direction" }
        if delta > 0 { return "Turn right \(Int(abs(delta).rounded()))°" }
        return "Turn left \(Int(abs(delta).rounded()))°"
    }

    static func normalizedDelta(from heading: Double, to target: Double) -> Double {
        var delta = target - heading
        while delta > 180 { delta -= 360 }
        while delta < -180 { delta += 360 }
        return delta
    }
}
