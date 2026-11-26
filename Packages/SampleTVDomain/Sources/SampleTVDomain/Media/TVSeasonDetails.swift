import Foundation

public struct TVSeasonDetails: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let seasonNumber: Int
    public let name: String
    public let overview: String
    public let airDate: String?
    public let posterPath: String?
    public let episodes: [TVEpisode]

    public init(
        id: Int,
        seasonNumber: Int,
        name: String,
        overview: String = "",
        airDate: String? = nil,
        posterPath: String? = nil,
        episodes: [TVEpisode] = []
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.airDate = airDate
        self.posterPath = posterPath
        self.episodes = episodes
    }
}
