import ActivityKit
import Foundation

struct PassActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endDate: Date
        var statusLine: String
    }

    var placeName: String
    var startAzCompass: String
}
