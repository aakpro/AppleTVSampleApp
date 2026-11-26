import Foundation
import SampleTVDomain

struct RecommendationsDTO: Decodable, Sendable {
    let results: [MediaDTO]
}

struct DetailsDTO: Decodable, Sendable {
    let media: MediaDTO
    let genres: [GenreDTO]
    let runtime: Int?
    let numberOfSeasons: Int?
    let recommendations: RecommendationsDTO?
    let videos: VideosResponseDTO?

    enum CodingKeys: String, CodingKey {
        case genres, runtime, recommendations, videos
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
        videos = try container.decodeIfPresent(VideosResponseDTO.self, forKey: .videos)
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
            recommendations: (recommendations?.results ?? []).compactMap { $0.toDomain(defaultKind: kind) },
            videos: (videos?.results ?? []).map {
                MediaVideo(
                    id: $0.id,
                    kind: $0.videoKind,
                    name: $0.name,
                    site: $0.site,
                    key: $0.key,
                    language: $0.iso6391 ?? "en"
                )
            }
        )
    }
}
