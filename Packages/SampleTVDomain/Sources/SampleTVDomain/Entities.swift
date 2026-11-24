import Foundation

public enum MediaKind: String, Codable, Sendable, CaseIterable {
    case movie
    case tv
}

/// TMDB movie and TV ids live in separate namespaces, so an id alone is not unique.
public struct MediaID: Codable, Hashable, Sendable {
    public let kind: MediaKind
    public let value: Int

    public init(kind: MediaKind, value: Int) {
        self.kind = kind
        self.value = value
    }
}

public struct Genre: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

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

public struct MediaDetails: Codable, Hashable, Sendable {
    public let item: MediaItem
    public let genres: [Genre]
    public let runtimeMinutes: Int?
    public let seasonCount: Int?
    public let recommendations: [MediaItem]

    public init(
        item: MediaItem,
        genres: [Genre] = [],
        runtimeMinutes: Int? = nil,
        seasonCount: Int? = nil,
        recommendations: [MediaItem] = []
    ) {
        self.item = item
        self.genres = genres
        self.runtimeMinutes = runtimeMinutes
        self.seasonCount = seasonCount
        self.recommendations = recommendations
    }
}

public struct ResultPage<Element: Sendable & Equatable>: Sendable, Equatable {
    public let items: [Element]
    public let page: Int
    public let totalPages: Int

    public var hasNextPage: Bool { page < totalPages }

    public init(items: [Element], page: Int, totalPages: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
    }

    public static var empty: ResultPage { .init(items: [], page: 1, totalPages: 1) }
}
