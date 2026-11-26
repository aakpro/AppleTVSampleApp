import Foundation
import SampleTVDomain

struct PageDTO: Decodable, Sendable {
    let page: Int
    let results: [MediaDTO]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}
