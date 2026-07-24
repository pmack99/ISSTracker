import Foundation

struct PeopleInSpaceResponse: Decodable {
    let message: String
    let number: Int
    let people: [SpaceTraveler]
}

struct SpaceTraveler: Decodable, Identifiable, Equatable {
    let name: String
    let craft: String

    var id: String { "\(craft)-\(name)" }

    var isOnISS: Bool {
        craft.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() == "ISS"
    }
}

extension PeopleInSpaceResponse {
    var issCrew: [SpaceTraveler] {
        people.filter(\.isOnISS).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
