import Foundation

struct ISSCabinTelemetry: Equatable {
    var cabinPressure: String?
    var cabinTemperature: String?
    var urineTankQuantity: String?
    var wasteWaterQuantity: String?
    var cleanWaterQuantity: String?
    var cabinCO2: String?
    var lastUpdated: Date?

    static let empty = ISSCabinTelemetry()

    var hasAnyValue: Bool {
        cabinPressure != nil
            || cabinTemperature != nil
            || urineTankQuantity != nil
            || wasteWaterQuantity != nil
            || cleanWaterQuantity != nil
            || cabinCO2 != nil
    }

    mutating func apply(itemID: String, value: String?) {
        guard let value, !value.isEmpty, value != "-" else { return }
        switch itemID {
        case ISSLiveCabinSymbols.cabinPressure:
            cabinPressure = formatPressure(value)
        case ISSLiveCabinSymbols.cabinTemperature:
            cabinTemperature = formatTemperature(value)
        case ISSLiveCabinSymbols.urineTankQuantity:
            urineTankQuantity = formatPercent(value)
        case ISSLiveCabinSymbols.wasteWaterQuantity:
            wasteWaterQuantity = formatPercent(value)
        case ISSLiveCabinSymbols.cleanWaterQuantity:
            cleanWaterQuantity = formatPercent(value)
        case ISSLiveCabinSymbols.cabinCO2:
            cabinCO2 = formatCO2(value)
        default:
            break
        }
        lastUpdated = .now
    }

    private func formatPressure(_ raw: String) -> String {
        if let n = Double(raw.trimmingCharacters(in: .whitespaces)) {
            return String(format: "%.1f mmHg", n)
        }
        return raw
    }

    private func formatTemperature(_ raw: String) -> String {
        if let c = Double(raw.trimmingCharacters(in: .whitespaces)) {
            let f = c * 9 / 5 + 32
            return String(format: "%.1f °C · %.0f °F", c, f)
        }
        return raw
    }

    private func formatPercent(_ raw: String) -> String {
        if let n = Double(raw.trimmingCharacters(in: .whitespaces)) {
            return String(format: "%.0f%%", n)
        }
        return raw
    }

    private func formatCO2(_ raw: String) -> String {
        if let n = Double(raw.trimmingCharacters(in: .whitespaces)) {
            return String(format: "%.2f mmHg", n)
        }
        return raw
    }
}

enum ISSLiveCabinSymbols {
    static let cabinPressure = "USLAB000058"
    static let cabinTemperature = "USLAB000059"
    static let urineTankQuantity = "NODE3000005"
    static let wasteWaterQuantity = "NODE3000008"
    static let cleanWaterQuantity = "NODE3000009"
    static let cabinCO2 = "NODE3000003"

    static let subscriptionItems = [
        cabinPressure,
        cabinTemperature,
        urineTankQuantity,
        wasteWaterQuantity,
        cleanWaterQuantity,
        cabinCO2,
    ]
}
