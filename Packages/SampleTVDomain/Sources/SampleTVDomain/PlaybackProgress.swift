import Foundation

/// Represents playback progress for a media item.
public struct PlaybackProgress: Codable, Hashable, Sendable {
    public let mediaID: MediaID
    public let position: TimeInterval
    public let duration: TimeInterval
    public let updatedAt: Date

    /// Creates a new playback progress record.
    public init(
        mediaID: MediaID,
        position: TimeInterval,
        duration: TimeInterval,
        updatedAt: Date = .now
    ) {
        self.mediaID = mediaID
        self.position = position
        self.duration = duration
        self.updatedAt = updatedAt
    }

    /// Returns true if the item should be considered as watched (position is at least 90% of duration).
    public var isWatched: Bool {
        duration > 0 && position / duration >= 0.9
    }
}

/// Port for storing and retrieving playback progress.
public protocol PlaybackProgressStore: Sendable {
    func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress?
    func saveProgress(_ progress: PlaybackProgress) async throws
    func clearProgress(for mediaID: MediaID) async throws
    func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress]
}
