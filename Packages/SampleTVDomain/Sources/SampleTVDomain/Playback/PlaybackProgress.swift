import Foundation

/// Represents playback progress for a media item scoped to a viewer profile.
public struct PlaybackProgress: Codable, Hashable, Sendable {
    public let profileID: String
    public let mediaID: MediaID
    public let position: TimeInterval
    public let duration: TimeInterval
    public let updatedAt: Date

    /// Creates a new playback progress record.
    public init(
        mediaID: MediaID,
        position: TimeInterval,
        duration: TimeInterval,
        updatedAt: Date = .now,
        profileID: String = ViewerProfile.defaultID
    ) {
        self.profileID = profileID
        self.mediaID = mediaID
        self.position = position
        self.duration = duration
        self.updatedAt = updatedAt
    }

    /// Returns true if the item should be considered watched (position >= 90% of duration).
    public var isWatched: Bool {
        duration > 0 && position / duration >= 0.9
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.mediaID = try container.decode(MediaID.self, forKey: .mediaID)
        self.position = try container.decode(TimeInterval.self, forKey: .position)
        self.duration = try container.decode(TimeInterval.self, forKey: .duration)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.profileID = try container.decodeIfPresent(String.self, forKey: .profileID)
            ?? ViewerProfile.defaultID
    }

    private enum CodingKeys: String, CodingKey {
        case mediaID, position, duration, updatedAt, profileID
    }
}

/// Port for storing and retrieving playback progress.
public protocol PlaybackProgressStore: Sendable {
    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress?
    func saveProgress(_ progress: PlaybackProgress) async throws
    func clearProgress(for mediaID: MediaID, profileID: String) async throws
    func clearAllProgress(for profileID: String) async throws
    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress]
}

public extension PlaybackProgressStore {
    func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress? {
        try await loadProgress(for: mediaID, profileID: ViewerProfile.defaultID)
    }

    func clearProgress(for mediaID: MediaID) async throws {
        try await clearProgress(for: mediaID, profileID: ViewerProfile.defaultID)
    }

    func clearAllProgress() async throws {
        try await clearAllProgress(for: ViewerProfile.defaultID)
    }

    func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress] {
        try await recentlyWatched(for: ViewerProfile.defaultID, maxCount: maxCount)
    }
}
