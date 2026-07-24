import Foundation

struct ISSPass: Identifiable, Equatable {
    let startUTC: TimeInterval
    let endUTC: TimeInterval
    let duration: Int
    let startAzCompass: String
    let endAzCompass: String
    let startEl: Double
    let maxEl: Double
    let magnitude: Double?

    var id: TimeInterval { startUTC }

    var startDate: Date { Date(timeIntervalSince1970: startUTC) }
    var endDate: Date { Date(timeIntervalSince1970: endUTC) }

    var durationFormatted: String {
        let minutes = duration / 60
        let seconds = duration % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }

    init(
        startUTC: TimeInterval,
        endUTC: TimeInterval,
        duration: Int,
        startAzCompass: String,
        endAzCompass: String,
        startEl: Double,
        maxEl: Double,
        magnitude: Double? = nil
    ) {
        self.startUTC = startUTC
        self.endUTC = endUTC
        self.duration = duration
        self.startAzCompass = startAzCompass
        self.endAzCompass = endAzCompass
        self.startEl = startEl
        self.maxEl = maxEl
        self.magnitude = magnitude
    }
}

extension ISSPass {
    init(from pass: ISSPassResponse.Pass) {
        startUTC = pass.startUTC
        endUTC = pass.endUTC
        duration = pass.duration
        startAzCompass = pass.startAzCompass
        endAzCompass = pass.endAzCompass
        startEl = pass.startEl
        maxEl = pass.maxEl
        magnitude = pass.mag
    }
}

// Legacy N2YO-shaped payload (kept for unit tests).
struct ISSPassResponse: Decodable {
    struct Info: Decodable {
        let passescount: Int
    }

    struct Pass: Decodable {
        let startUTC: TimeInterval
        let endUTC: TimeInterval
        let duration: Int
        let startAzCompass: String
        let endAzCompass: String
        let startEl: Double
        let maxEl: Double
        let mag: Double?
    }

    let info: Info
    let passes: [Pass]?
}
