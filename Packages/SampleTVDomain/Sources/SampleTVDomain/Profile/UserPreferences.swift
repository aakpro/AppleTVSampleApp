import Foundation

// MARK: - User Preferences

public struct UserPreferences: Codable, Hashable, Sendable {
    public var defaultKind: MediaKind
    public var autoplayTrailers: Bool

    public init(defaultKind: MediaKind = .movie, autoplayTrailers: Bool = true) {
        self.defaultKind = defaultKind
        self.autoplayTrailers = autoplayTrailers
    }
}
