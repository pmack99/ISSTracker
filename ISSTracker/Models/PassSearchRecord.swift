import Foundation
import SwiftData

@Model
final class PassSearchRecord {
    var placeName: String
    var passStart: Date
    var durationSeconds: Int
    var appearsFrom: String
    var departsTo: String
    var maxElevation: Double
    var searchedAt: Date

    init(
        placeName: String,
        passStart: Date,
        durationSeconds: Int,
        appearsFrom: String,
        departsTo: String,
        maxElevation: Double,
        searchedAt: Date = .now
    ) {
        self.placeName = placeName
        self.passStart = passStart
        self.durationSeconds = durationSeconds
        self.appearsFrom = appearsFrom
        self.departsTo = departsTo
        self.maxElevation = maxElevation
        self.searchedAt = searchedAt
    }
}
