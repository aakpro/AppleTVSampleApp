import Foundation

public enum MediaKind: String, Codable, Sendable, CaseIterable {
    case movie
    case tv
}

public enum VideoKind: String, Codable, Sendable, Hashable {
    case trailer
    case feature
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
