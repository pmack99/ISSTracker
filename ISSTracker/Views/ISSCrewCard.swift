import SwiftUI

struct ISSCrewCard: View {
    let crew: [SpaceTraveler]
    let isLoading: Bool
    let errorMessage: String?
    var retry: (() async -> Void)?

    var body: some View {
        ISSCrewListContent(
            crew: crew,
            isLoading: isLoading,
            errorMessage: errorMessage,
            retry: retry.map { retry in { Task { await retry() } } }
        )
        .issGroupedCard()
        .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
    }
}

#Preview {
    ISSCrewCard(
        crew: [
            SpaceTraveler(name: "Example Cosmonaut", craft: "ISS"),
            SpaceTraveler(name: "Example Astronaut", craft: "ISS"),
        ],
        isLoading: false,
        errorMessage: nil
    )
    .padding()
}
