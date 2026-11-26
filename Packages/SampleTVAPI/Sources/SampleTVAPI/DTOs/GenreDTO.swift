import Foundation
import SampleTVDomain

struct GenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

struct GenreListDTO: Decodable, Sendable {
    let genres: [GenreDTO]
}
