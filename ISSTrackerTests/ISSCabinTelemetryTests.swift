import Foundation
import Testing
@testable import ISSTracker

struct ISSCabinTelemetryTests {
    @Test func mapsLightstreamerItemsToDisplayFields() {
        var telemetry = ISSCabinTelemetry.empty
        telemetry.apply(itemID: ISSLiveCabinSymbols.cabinPressure, value: "760.12")
        telemetry.apply(itemID: ISSLiveCabinSymbols.cabinTemperature, value: "22.5")
        telemetry.apply(itemID: ISSLiveCabinSymbols.urineTankQuantity, value: "41")
        telemetry.apply(itemID: ISSLiveCabinSymbols.cabinCO2, value: "3.1")

        #expect(telemetry.cabinPressure == "760.1 mmHg")
        #expect(telemetry.cabinTemperature?.contains("22.5") == true)
        #expect(telemetry.urineTankQuantity == "41%")
        #expect(telemetry.cabinCO2 == "3.10 mmHg")
        #expect(telemetry.hasAnyValue)
    }
}
