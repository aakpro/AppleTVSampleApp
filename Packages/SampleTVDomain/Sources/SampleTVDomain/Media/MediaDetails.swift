import Foundation

public struct MediaVideo: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let kind: VideoKind
    public let name: String
    public let site: String
    public let key: String
    public let language: String

    public init(
        id: String,
        kind: VideoKind,
        name: String,
        site: String,
        key: String,
        language: String
    ) {
        self.id = id
        self.kind = kind
        self.name = name
        self.site = site
        self.key = key
        self.language = language
    }
}

public struct MediaDetails: Codable, Hashable, Sendable {
    public let item: MediaItem
    public let genres: [Genre]
    public let runtimeMinutes: Int?
    public let seasonCount: Int?
    public let recommendations: [MediaItem]
    public let videos: [MediaVideo]
    public let seasons: [TVSeason]

    public init(
        item: MediaItem,
        genres: [Genre] = [],
        runtimeMinutes: Int? = nil,
        seasonCount: Int? = nil,
        recommendations: [MediaItem] = [],
        videos: [MediaVideo] = [],
        seasons: [TVSeason] = []
    ) {
        self.item = item
        self.genres = genres
        self.runtimeMinutes = runtimeMinutes
        self.seasonCount = seasonCount
        self.recommendations = recommendations
        self.videos = videos
        self.seasons = seasons
    }
}
