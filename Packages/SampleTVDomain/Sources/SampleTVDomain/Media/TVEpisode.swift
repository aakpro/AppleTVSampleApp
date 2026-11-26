import Foundation

public struct TVEpisode: Identifiable, Codable, Hashable, Sendable {
    public let id: Int
    public let episodeNumber: Int
    public let seasonNumber: Int
    public let name: String
    public let overview: String
    public let airDate: String?
    public let runtimeMinutes: Int?
    public let stillPath: String?
    public let rating: Double?

    public init(
        id: Int,
        episodeNumber: Int,
        seasonNumber: Int,
        name: String,
        overview: String = "",
        airDate: String? = nil,
        runtimeMinutes: Int? = nil,
        stillPath: String? = nil,
        rating: Double? = nil
    ) {
        self.id = id
        self.episodeNumber = episodeNumber
        self.seasonNumber = seasonNumber
        self.name = name
        self.overview = overview
        self.airDate = airDate
        self.runtimeMinutes = runtimeMinutes
        self.stillPath = stillPath
        self.rating = rating
    }

    public var episodeCode: String {
        "S\(seasonNumber) E\(episodeNumber)"
    }
}
