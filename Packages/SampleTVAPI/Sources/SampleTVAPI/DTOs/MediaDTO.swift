import Foundation
import SampleTVDomain

/// One DTO for both kinds: movies use `title`/`release_date`, TV uses `name`/`first_air_date`.
struct MediaDTO: Decodable, Sendable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let overview: String?
    let releaseDate: String?
    let firstAirDate: String?
    let genreIDs: [Int]?
    let voteAverage: Double?
    let posterPath: String?
    let backdropPath: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case mediaType = "media_type"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
        case voteAverage = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    /// Returns nil for results that are not playable media (e.g. `person` in `/search/multi`).
    func toDomain(defaultKind: MediaKind?) -> MediaItem? {
        let kind: MediaKind
        switch mediaType {
        case "movie": kind = .movie
        case "tv": kind = .tv
        case nil:
            guard let defaultKind else { return nil }
            kind = defaultKind
        default: return nil
        }
        let dateString = releaseDate ?? firstAirDate
        let year = dateString.flatMap { Int($0.prefix(4)) }
        return MediaItem(
            id: MediaID(kind: kind, value: id),
            title: title ?? name ?? "",
            overview: overview ?? "",
            releaseYear: year,
            genreIDs: genreIDs ?? [],
            rating: voteAverage.flatMap { $0 > 0 ? $0 : nil },
            posterPath: posterPath,
            backdropPath: backdropPath
        )
    }
}
