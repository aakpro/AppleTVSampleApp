import Foundation
import SampleTVDomain

struct TVSeasonDTO: Decodable, Sendable {
    let id: Int
    let seasonNumber: Int
    let name: String?
    let overview: String?
    let airDate: String?
    let posterPath: String?
    let episodeCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case posterPath = "poster_path"
        case episodeCount = "episode_count"
    }

    func toDomain() -> TVSeason {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = seasonNumber == 0 ? "Specials" : "Season \(seasonNumber)"
        return TVSeason(
            id: id,
            seasonNumber: seasonNumber,
            name: trimmedName.isEmpty ? fallbackName : trimmedName,
            overview: overview ?? "",
            airDate: airDate,
            episodeCount: episodeCount ?? 0,
            posterPath: posterPath
        )
    }

    /// Orders regular numbered seasons ascending and places populated Specials (season 0) last.
    static func normalizedSeasons(_ dtos: [TVSeasonDTO]?) -> [TVSeason] {
        let mapped = (dtos ?? []).map { $0.toDomain() }
        let regular = mapped.filter { $0.seasonNumber > 0 }.sorted { $0.seasonNumber < $1.seasonNumber }
        let specials = mapped.filter { $0.seasonNumber == 0 && $0.episodeCount > 0 }
        return regular + specials
    }
}

struct TVEpisodeDTO: Decodable, Sendable {
    let id: Int
    let episodeNumber: Int
    let seasonNumber: Int?
    let name: String?
    let overview: String?
    let airDate: String?
    let runtime: Int?
    let stillPath: String?
    let voteAverage: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
    }

    func toDomain(defaultSeasonNumber: Int) -> TVEpisode {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let episodeName = trimmedName.isEmpty ? "Episode \(episodeNumber)" : trimmedName
        return TVEpisode(
            id: id,
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber ?? defaultSeasonNumber,
            name: episodeName,
            overview: overview ?? "",
            airDate: airDate,
            runtimeMinutes: runtime,
            stillPath: stillPath,
            rating: voteAverage.flatMap { $0 > 0 ? $0 : nil }
        )
    }
}

struct TVSeasonDetailsDTO: Decodable, Sendable {
    let id: Int?
    let seasonNumber: Int
    let name: String?
    let overview: String?
    let airDate: String?
    let posterPath: String?
    let episodes: [TVEpisodeDTO]?

    enum CodingKeys: String, CodingKey {
        case id, name, overview, episodes
        case seasonNumber = "season_number"
        case airDate = "air_date"
        case posterPath = "poster_path"
    }

    func toDomain() -> TVSeasonDetails {
        let trimmedName = (name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = seasonNumber == 0 ? "Specials" : "Season \(seasonNumber)"
        let domainEpisodes = (episodes ?? [])
            .sorted { $0.episodeNumber < $1.episodeNumber }
            .map { $0.toDomain(defaultSeasonNumber: seasonNumber) }

        return TVSeasonDetails(
            id: id ?? seasonNumber,
            seasonNumber: seasonNumber,
            name: trimmedName.isEmpty ? fallbackName : trimmedName,
            overview: overview ?? "",
            airDate: airDate,
            posterPath: posterPath,
            episodes: domainEpisodes
        )
    }
}
