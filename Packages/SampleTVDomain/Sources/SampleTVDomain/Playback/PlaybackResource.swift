import Foundation

public enum PlaybackResourceKind: String, Codable, Sendable, Hashable {
    case feature
    case trailer
}

public struct PlayableResource: Sendable, Equatable {
    public let url: URL
    public let kind: PlaybackResourceKind
    public let title: String
    public let subtitle: String?
    public let trackProgress: Bool

    public init(
        url: URL,
        kind: PlaybackResourceKind,
        title: String,
        subtitle: String? = nil,
        trackProgress: Bool
    ) {
        self.url = url
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.trackProgress = trackProgress
    }
}

public protocol PlaybackResourceResolver: Sendable {
    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource]
    func resolve(_ mediaID: MediaID, genreIDs: [Int], episode: TVEpisode?) async throws -> [PlayableResource]
}

public extension PlaybackResourceResolver {
    func resolve(_ mediaID: MediaID, genreIDs: [Int], episode: TVEpisode?) async throws -> [PlayableResource] {
        try await resolve(mediaID, genreIDs: genreIDs)
    }
}

public struct ResolvePlaybackResources: Sendable {
    private let resolver: any PlaybackResourceResolver

    public init(resolver: any PlaybackResourceResolver) {
        self.resolver = resolver
    }

    public func callAsFunction(
        _ mediaID: MediaID,
        genreIDs: [Int] = [],
        episode: TVEpisode? = nil
    ) async throws -> [PlayableResource] {
        try await resolver.resolve(mediaID, genreIDs: genreIDs, episode: episode)
    }

    public func resolveFirst(
        _ mediaID: MediaID,
        genreIDs: [Int] = [],
        episode: TVEpisode? = nil,
        kind: PlaybackResourceKind
    ) async throws -> PlayableResource? {
        let resources = try await resolver.resolve(mediaID, genreIDs: genreIDs, episode: episode)
        return resources.first { $0.kind == kind }
    }
}
