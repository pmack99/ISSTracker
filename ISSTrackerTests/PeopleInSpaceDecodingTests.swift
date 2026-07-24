import Foundation
import Testing
@testable import ISSTracker

struct PeopleInSpaceDecodingTests {
    @Test func decodesOpenNotifyPayloadAndFiltersISS() throws {
        let json = """
        {
          "message": "success",
          "number": 3,
          "people": [
            { "craft": "ISS", "name": "Ada Astronaut" },
            { "craft": "Tiangong", "name": "Other Traveler" },
            { "craft": "ISS", "name": "Bob Cosmonaut" }
          ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(PeopleInSpaceResponse.self, from: json)
        #expect(decoded.number == 3)
        #expect(decoded.issCrew.count == 2)
        #expect(decoded.issCrew.map(\.name) == ["Ada Astronaut", "Bob Cosmonaut"])
    }
}
