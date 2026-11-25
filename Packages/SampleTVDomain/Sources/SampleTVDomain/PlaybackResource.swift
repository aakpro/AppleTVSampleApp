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
}
