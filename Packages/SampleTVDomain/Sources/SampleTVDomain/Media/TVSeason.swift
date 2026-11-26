import Foundation

public struct TVSeason: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let seasonNumber: Int
    public let name: String
    public let overview: String
    public let airDate: String?
    public let episodeCount: Int
    public let posterPath: String?

    public init(
        id: Int,
        seasonNumber: Int,
        name: String,
        overview: String = "",
        airDate: String? = nil,
        episodeCount: Int = 0,
        posterPath: String? = nil
    ) {
        self.id = id
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.airDate = airDate
        self.episodeCount = episodeCount
        self.posterPath = posterPath
    }
}
