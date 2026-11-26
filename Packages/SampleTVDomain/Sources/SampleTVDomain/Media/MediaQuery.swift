import Foundation

public enum MediaSort: String, Codable, Sendable, CaseIterable {
    case popularity
    case rating
    case newest
}

public struct MediaFilter: Equatable, Sendable {
    public var kind: MediaKind
    public var genreIDs: Set<Int>
    public var years: ClosedRange<Int>?
    public var minimumRating: Double?
    public var sort: MediaSort

    public init(
        kind: MediaKind = .tv,
        genreIDs: Set<Int> = [],
        years: ClosedRange<Int>? = nil,
        minimumRating: Double? = nil,
        sort: MediaSort = .popularity
    ) {
        self.kind = kind
        self.genreIDs = genreIDs
        self.years = years
        self.minimumRating = minimumRating
        self.sort = sort
    }
}

/// A validated search request. Construction fails for input that is too short to search.
public struct SearchQuery: Equatable, Sendable {
    public static let minimumLength = 2

    public let text: String
    public let kind: MediaKind?

    public init?(_ rawText: String, kind: MediaKind? = nil) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumLength else { return nil }
        self.text = trimmed
        self.kind = kind
    }
}

extension MediaFilter {
    /// Applies the filter on the client. Used for search results, because TMDB's search
    /// endpoints cannot filter by genre, year or rating. Items with unknown values are excluded
    /// only when the corresponding criterion is set.
    public func matches(_ item: MediaItem) -> Bool {
        if item.id.kind != kind { return false }
        if !genreIDs.isEmpty, genreIDs.isDisjoint(with: item.genreIDs) { return false }
        if let years {
            guard let year = item.releaseYear, years.contains(year) else { return false }
        }
        if let minimumRating {
            guard let rating = item.rating, rating >= minimumRating else { return false }
        }
        return true
    }
}
