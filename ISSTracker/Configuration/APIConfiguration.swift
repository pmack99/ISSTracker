import Foundation

enum APIConfiguration {
    static let issNoradID = 25544

    /// Injected via Config/Secrets.xcconfig → Info.plist (`N2YOAPIKey`).
    static var n2yoAPIKey: String {
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "N2YOAPIKey") as? String {
            let trimmed = plistKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty, !trimmed.contains("$("), trimmed != "YOUR_N2YO_API_KEY_HERE" {
                return trimmed
            }
        }
        if let envKey = ProcessInfo.processInfo.environment["N2YO_API_KEY"] {
            let trimmed = envKey.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return ""
    }

    static var isN2YOConfigured: Bool { !n2yoAPIKey.isEmpty }
}
