import Foundation
import SampleTVDomain

/// Represents playback progress for a media item
public struct PlaybackProgress: Codable, Hashable, Sendable {
    public let mediaID: MediaID
    public let position: TimeInterval
    public let duration: TimeInterval
    public let updatedAt: Date
    
    /// Creates a new playback progress record
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
    
    /// Returns true if the item should be considered as watched (position is at least 90% of duration)
    public var isWatched: Bool {
        duration > 0 && position / duration >= 0.9
    }
}

/// Protocol for storing and retrieving playback progress
public protocol PlaybackProgressStore: Sendable {
    /// Loads existing progress for a media item
    func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress?
    
    /// Saves the current progress for a media item
    func saveProgress(_ progress: PlaybackProgress) async throws
    
    /// Clears all progress for a specific media item 
    func clearProgress(for mediaID: MediaID) async throws
    
    /// Gets recently watched items (sorted by most recently updated)
    func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress]
}