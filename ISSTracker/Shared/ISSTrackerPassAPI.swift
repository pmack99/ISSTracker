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

enum ISSTrackerPassAPI {
    static let baseURL = "https://iss.cdnspace.ca/api/passes"

    static func mapPasses(from records: [CDNPassRecord], now: Date = .now) -> [ISSPass] {
        let nowSeconds = now.timeIntervalSince1970
        return records
            .compactMap { record -> ISSPass? in
                let pass = ISSPass(from: record)
                return pass.startUTC >= nowSeconds - 60 ? pass : nil
            }
            .sorted { $0.startUTC < $1.startUTC }
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
}
