import Foundation

struct NASAImageItem: Identifiable, Equatable {
    let id: String
    let imageURL: URL
    let title: String
    let description: String
}

struct NASASearchResponse: Decodable {
    struct Collection: Decodable {
        let items: [Item]
    }

    struct Item: Decodable {
        let data: [DataItem]
        let links: [LinkItem]?
    }

    struct DataItem: Decodable {
        let title: String?
        let description: String?
        let nasa_id: String?
    }

    struct LinkItem: Decodable {
        let href: String
        let rel: String?
    }

    let collection: Collection
}
