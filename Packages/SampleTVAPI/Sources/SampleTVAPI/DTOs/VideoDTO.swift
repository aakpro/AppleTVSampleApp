import Foundation
import SampleTVDomain

struct VideoDTO: Decodable, Sendable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let iso6391: String?

    enum CodingKeys: String, CodingKey {
        case id, key, name, site, type
        case iso6391 = "iso_639_1"
    }

    var videoKind: VideoKind {
        switch type.lowercased() {
        case "trailer": .trailer
        default: .feature
        }
    }
}

struct VideosResponseDTO: Decodable, Sendable {
    let results: [VideoDTO]
}
