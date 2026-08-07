import Foundation

struct CDNPassRecord: Decodable {
    let riseTime: Double
    let riseAzimuth: Double
    let maxTime: Double
    let maxElevation: Double
    let setTime: Double
    let setAzimuth: Double
    let magnitude: Double?
    let quality: String?
}

struct PolluxPassResponse: Decodable {
    let passes: [PolluxPassRecord]
}

struct PolluxPassRecord: Decodable {
    struct Event: Decodable {
        let time: String
        let azimuth_deg: Double?
        let compass: String?
    }

    struct Culmination: Decodable {
        let elevation_deg: Double
    }

    let rise: Event
    let set: Event
    let culmination: Culmination
    let duration_sec: Int?
}

enum ISSTrackerPassAPI {
    static let cdnBaseURL = "https://iss.cdnspace.ca/api/passes"
    static let polluxBaseURL = "https://iss-api.polluxlabs.io/iss-pass"

    private static let iso8601Parser: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static func cdnURL(latitude: Double, longitude: Double, days: Int) -> URL? {
        var components = URLComponents(string: cdnBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "days", value: String(min(max(days, 1), 30))),
        ]
        return components?.url
    }

    static func polluxURL(latitude: Double, longitude: Double) -> URL? {
        var components = URLComponents(string: polluxBaseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "visible_only", value: "true"),
        ]
        return components?.url
    }

    static func mapPasses(from records: [CDNPassRecord], now: Date = .now) -> [ISSPass] {
        let nowSeconds = now.timeIntervalSince1970
        return records
            .compactMap { record -> ISSPass? in
                let pass = ISSPass(from: record)
                return pass.startUTC >= nowSeconds - 60 ? pass : nil
            }
            .sorted { $0.startUTC < $1.startUTC }
    }

    static func mapPasses(from records: [PolluxPassRecord], now: Date = .now) -> [ISSPass] {
        let nowSeconds = now.timeIntervalSince1970
        return records
            .compactMap { record -> ISSPass? in
                guard let pass = ISSPass(from: record) else { return nil }
                return pass.startUTC >= nowSeconds - 60 ? pass : nil
            }
            .sorted { $0.startUTC < $1.startUTC }
    }

    static func parseISO8601(_ value: String) -> Date? {
        if let date = iso8601Parser.date(from: value) {
            return date
        }
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }
}

extension ISSPass {
    init(from record: CDNPassRecord) {
        let riseSeconds = record.riseTime / 1000
        let setSeconds = record.setTime / 1000
        let duration = max(0, Int((setSeconds - riseSeconds).rounded()))

        startUTC = riseSeconds
        endUTC = setSeconds
        self.duration = duration
        startAzCompass = CompassAzimuth.label(for: record.riseAzimuth)
        endAzCompass = CompassAzimuth.label(for: record.setAzimuth)
        startEl = 0
        maxEl = record.maxElevation
        magnitude = record.magnitude
    }

    init?(from record: PolluxPassRecord) {
        guard
            let riseDate = ISSTrackerPassAPI.parseISO8601(record.rise.time),
            let setDate = ISSTrackerPassAPI.parseISO8601(record.set.time)
        else {
            return nil
        }

        let riseSeconds = riseDate.timeIntervalSince1970
        let setSeconds = setDate.timeIntervalSince1970
        startUTC = riseSeconds
        endUTC = setSeconds
        duration = record.duration_sec ?? max(0, Int((setSeconds - riseSeconds).rounded()))
        startAzCompass = record.rise.compass
            ?? CompassAzimuth.label(for: record.rise.azimuth_deg ?? 0)
        endAzCompass = record.set.compass
            ?? CompassAzimuth.label(for: record.set.azimuth_deg ?? 0)
        startEl = 0
        maxEl = record.culmination.elevation_deg
        magnitude = nil
    }
}
