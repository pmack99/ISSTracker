import Foundation
import SwiftData

@Model
final class SavedLocation {
    var name: String
    var latitude: Double
    var longitude: Double
    @Attribute(originalName: "isWidgetPrimary") var isDefaultLocation: Bool
    var createdAt: Date

    init(
        name: String,
        latitude: Double,
        longitude: Double,
        isDefaultLocation: Bool = false,
        createdAt: Date = .now
    ) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.isDefaultLocation = isDefaultLocation
        self.createdAt = createdAt
    }
}
