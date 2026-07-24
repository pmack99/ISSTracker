import Foundation

struct SharedPassSnapshot: Codable, Equatable {
    var placeName: String
    var startUTC: TimeInterval
    var endUTC: TimeInterval
    var startAzCompass: String
    var maxEl: Double
    var updatedAt: TimeInterval

    var startDate: Date { Date(timeIntervalSince1970: startUTC) }
    var endDate: Date { Date(timeIntervalSince1970: endUTC) }
}

enum SharedPassStorage {
    static let appGroupID = "group.com.pmack99.ISSTracker"
    private static let snapshotKey = "nextPassSnapshot"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    static func load() -> SharedPassSnapshot? {
        guard let defaults,
              let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(SharedPassSnapshot.self, from: data)
        else { return nil }
        return snapshot
    }
}
