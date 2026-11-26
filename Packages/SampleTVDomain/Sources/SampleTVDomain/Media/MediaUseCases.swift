import Foundation

public struct DiscoverMedia: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    public func callAsFunction(
        _ filter: MediaFilter,
        page: Int = 1
    ) async throws -> ResultPage<MediaItem> {
        try await repository.discover(filter, page: max(page, 1))
    }
}

public struct SearchMedia: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    /// Returns an empty page without touching the repository when the text is too short.
    public func callAsFunction(
        _ rawText: String,
        kind: MediaKind? = nil,
        page: Int = 1
    ) async throws -> ResultPage<MediaItem> {
        guard let query = SearchQuery(rawText, kind: kind) else { return .empty }
        return try await repository.search(query, page: max(page, 1))
    }
}

public struct GetMediaDetails: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ id: MediaID) async throws -> MediaDetails {
        try await repository.details(of: id)
    }
}

public struct GetTVSeasonDetails: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    public func callAsFunction(of id: MediaID, seasonNumber: Int) async throws -> TVSeasonDetails {
        guard id.kind == .tv && seasonNumber >= 0 else {
            throw MediaError.notFound
        }
        return try await repository.seasonDetails(of: id, seasonNumber: seasonNumber)
    }
}
