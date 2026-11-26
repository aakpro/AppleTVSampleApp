import Foundation

public struct MediaItem: Codable, Hashable, Sendable, Identifiable {
    public let id: MediaID
    public let title: String
    public let overview: String
    public let releaseYear: Int?
    public let genreIDs: [Int]
    public let rating: Double?
    public let posterPath: String?
    public let backdropPath: String?

    public init(
        id: MediaID,
        title: String,
        overview: String = "",
        releaseYear: Int? = nil,
        genreIDs: [Int] = [],
        rating: Double? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseYear = releaseYear
        self.genreIDs = genreIDs
        self.rating = rating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
    }
}
