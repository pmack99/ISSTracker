import Foundation

enum StoreErrorMessage {
    static func text(for error: Error) -> String {
        if let api = error as? ISSAPIError {
            return api.localizedDescription
        }
        return error.localizedDescription
    }
}
