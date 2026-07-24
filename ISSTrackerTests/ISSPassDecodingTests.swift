import Foundation
import Testing
@testable import ISSTracker

struct ISSPassDecodingTests {
    @Test func decodesCDNPassPayloadAndMapsToISSPass() throws {
        let json = """
        [{
          "riseTime": 1700000000000,
          "riseAzimuth": 225,
          "maxTime": 1700000150000,
          "maxElevation": 42.5,
          "setTime": 1700000300000,
          "setAzimuth": 45,
          "magnitude": -1.2,
          "quality": "good"
        }]
        """.data(using: .utf8)!

        let records = try JSONDecoder().decode([CDNPassRecord].self, from: json)
        #expect(records.count == 1)

        let pass = ISSPass(from: try #require(records.first))
        #expect(pass.startUTC == 1_700_000_000)
        #expect(pass.endUTC == 1_700_000_300)
        #expect(pass.duration == 300)
        #expect(pass.maxEl == 42.5)
        #expect(pass.magnitude == -1.2)
        #expect(pass.startAzCompass == "SW")
        #expect(pass.endAzCompass == "NE")
    }

    @Test func compassLabelFromDegrees() {
        #expect(CompassAzimuth.label(for: 0) == "N")
        #expect(CompassAzimuth.label(for: 90) == "E")
        #expect(CompassAzimuth.label(for: 225) == "SW")
    }

    @Test func decodesN2YOPassPayload() throws {
        let json = """
        {
          "info": { "passescount": 1 },
          "passes": [{
            "startUTC": 1700000000,
            "endUTC": 1700000300,
            "duration": 300,
            "startAzCompass": "SW",
            "endAzCompass": "NE",
            "startEl": 10,
            "maxEl": 42.5,
            "mag": -1.2
          }]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(ISSPassResponse.self, from: json)
        #expect(decoded.info.passescount == 1)
        #expect(decoded.passes?.count == 1)

        let pass = ISSPass(from: try #require(decoded.passes?.first))
        #expect(pass.startUTC == 1_700_000_000)
        #expect(pass.maxEl == 42.5)
        #expect(pass.magnitude == -1.2)
        #expect(pass.startAzCompass == "SW")
    }

    @Test func durationFormattedIncludesMinutesAndSeconds() {
        let pass = ISSPass(
            startUTC: 0,
            endUTC: 300,
            duration: 125,
            startAzCompass: "N",
            endAzCompass: "E",
            startEl: 5,
            maxEl: 30
        )
        #expect(pass.durationFormatted == "2m 5s")
    }
}
