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

struct GenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

struct GenreListDTO: Decodable, Sendable {
    let genres: [GenreDTO]
}

struct RecommendationsDTO: Decodable, Sendable {
    let results: [MediaDTO]
}

struct DetailsDTO: Decodable, Sendable {
    let media: MediaDTO
    let genres: [GenreDTO]
    let runtime: Int?
    let numberOfSeasons: Int?
    let recommendations: RecommendationsDTO?

    enum CodingKeys: String, CodingKey {
        case genres, runtime, recommendations
        case numberOfSeasons = "number_of_seasons"
    }

    init(from decoder: Decoder) throws {
        // The detail payload is the list payload plus extras, so reuse MediaDTO for the shared part.
        media = try MediaDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genres = try container.decodeIfPresent([GenreDTO].self, forKey: .genres) ?? []
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        recommendations = try container.decodeIfPresent(RecommendationsDTO.self, forKey: .recommendations)
    }

    func toDomain(kind: MediaKind) throws -> MediaDetails {
        guard var item = media.toDomain(defaultKind: kind) else { throw MediaError.decoding }
        // Detail responses carry `genres` objects instead of `genre_ids`.
        item = MediaItem(
            id: item.id, title: item.title, overview: item.overview, releaseYear: item.releaseYear,
            genreIDs: genres.map(\.id), rating: item.rating,
            posterPath: item.posterPath, backdropPath: item.backdropPath
        )
        return MediaDetails(
            item: item,
            genres: genres.map { Genre(id: $0.id, name: $0.name) },
            runtimeMinutes: runtime,
            seasonCount: numberOfSeasons,
            recommendations: (recommendations?.results ?? []).compactMap { $0.toDomain(defaultKind: kind) }
        )
    }
}