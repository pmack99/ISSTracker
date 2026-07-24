import Foundation
import SwiftData

@Model
final class SavedLocation {
    var name: String
    var latitude: Double
    var longitude: Double
    var isWidgetPrimary: Bool
    var createdAt: Date

    init(name: String, latitude: Double, longitude: Double, isWidgetPrimary: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isWidgetPrimary = isWidgetPrimary
        self.createdAt = createdAt
    }
}
