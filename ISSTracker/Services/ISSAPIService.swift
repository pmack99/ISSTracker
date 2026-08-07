import Foundation

enum ISSAPIError: LocalizedError {
    case invalidURL
    case badResponse
    case noPasses
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Could not build the request URL."
        case .badResponse: "The space station service returned an error."
        case .noPasses: "No visible passes in the next 10 days for this location."
        case .decodingFailed: "Could not read the response from the server."
        }
    }
}

struct ISSAPIService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCurrentPosition() async throws -> ISSPosition {
        let url = URL(string: "https://api.wheretheiss.at/v1/satellites/\(APIConfiguration.issNoradID)")!
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ISSAPIError.badResponse
        }
        let decoder = JSONDecoder()
        return try decoder.decode(ISSPosition.self, from: data)
    }

    func fetchVisualPasses(latitude: Double, longitude: Double, days: Int = 10, maxPasses: Int = 300) async throws -> [ISSPass] {
        do {
            let polluxPasses = try await fetchPolluxPasses(latitude: latitude, longitude: longitude)
            guard !polluxPasses.isEmpty else { throw ISSAPIError.noPasses }
            return limited(polluxPasses, maxPasses: maxPasses)
        } catch ISSAPIError.noPasses {
            throw ISSAPIError.noPasses
        } catch {
            let cdnPasses = try await fetchCDNPasses(latitude: latitude, longitude: longitude, days: days)
            return limited(cdnPasses, maxPasses: maxPasses)
        }
    }

    private func fetchPolluxPasses(latitude: Double, longitude: Double) async throws -> [ISSPass] {
        guard let url = ISSTrackerPassAPI.polluxURL(latitude: latitude, longitude: longitude) else {
            throw ISSAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ISSAPIError.badResponse
        }

        let decoded = try JSONDecoder().decode(PolluxPassResponse.self, from: data)
        return ISSTrackerPassAPI.mapPasses(from: decoded.passes)
    }

    private func fetchCDNPasses(latitude: Double, longitude: Double, days: Int) async throws -> [ISSPass] {
        guard let url = ISSTrackerPassAPI.cdnURL(latitude: latitude, longitude: longitude, days: days) else {
            throw ISSAPIError.invalidURL
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ISSAPIError.badResponse
        }

        let decoded = try JSONDecoder().decode([CDNPassRecord].self, from: data)
        let passes = ISSTrackerPassAPI.mapPasses(from: decoded)
        guard !passes.isEmpty else { throw ISSAPIError.noPasses }
        return passes
    }

    private func limited(_ passes: [ISSPass], maxPasses: Int) -> [ISSPass] {
        guard passes.count > maxPasses else { return passes }
        return Array(passes.prefix(maxPasses))
    }

    func fetchISSImages(limit: Int = 40) async throws -> [NASAImageItem] {
        var components = URLComponents(string: "https://images-api.nasa.gov/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: "iss"),
            URLQueryItem(name: "media_type", value: "image"),
        ]
        guard let url = components.url else { throw ISSAPIError.invalidURL }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ISSAPIError.badResponse
        }

        let search = try JSONDecoder().decode(NASASearchResponse.self, from: data)
        var items: [NASAImageItem] = []

        for item in search.collection.items.prefix(limit) {
            guard let dataItem = item.data.first,
                  let href = item.links?.first(where: { $0.rel == "preview" || $0.href.contains(".jpg") || $0.href.contains(".png") })?.href
                    ?? item.links?.first?.href,
                  let imageURL = URL(string: href)
            else { continue }

            let id = dataItem.nasa_id ?? href
            items.append(
                NASAImageItem(
                    id: id,
                    imageURL: imageURL,
                    title: dataItem.title ?? "ISS",
                    description: dataItem.description ?? ""
                )
            )
        }
        return items
    }

    func fetchPeopleInSpace() async throws -> PeopleInSpaceResponse {
        // Open Notify serves this endpoint over HTTP only; ATS exception is in Info.plist.
        guard let url = URL(string: "http://api.open-notify.org/astros.json") else {
            throw ISSAPIError.invalidURL
        }
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200 ..< 300).contains(http.statusCode) else {
            throw ISSAPIError.badResponse
        }
        let decoded = try JSONDecoder().decode(PeopleInSpaceResponse.self, from: data)
        guard decoded.message.lowercased() == "success" else {
            throw ISSAPIError.badResponse
        }
        return decoded
    }
}
