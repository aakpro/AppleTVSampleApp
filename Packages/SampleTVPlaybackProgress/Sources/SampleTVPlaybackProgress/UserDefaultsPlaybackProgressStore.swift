import Foundation
import SampleTVDomain

/// UserDefaults-based implementation of PlaybackProgressStore
public struct UserDefaultsPlaybackProgressStore: PlaybackProgressStore {
    private let userDefaults = UserDefaults(suiteName: "com.sampletv.progress") ?? .standard
    private let progressKey = "PlaybackProgress"
    private let recentlyWatchedKey = "RecentlyWatched"
    
    public init() {}
    
    public func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress? {
        let data = userDefaults.data(forKey: progressKey(for: mediaID))
        guard let data else { return nil }
        
        do {
            let progress = try JSONDecoder().decode(PlaybackProgress.self, from: data)
            return progress
        } catch {
            // If we can't decode it, remove it and return nil
            userDefaults.removeObject(forKey: progressKey(for: mediaID))
            return nil
        }
    }
    
    public func saveProgress(_ progress: PlaybackProgress) async throws {
        let data = try JSONEncoder().encode(progress)
        userDefaults.set(data, forKey: progressKey(for: progress.mediaID))
        
        // Also update recently watched list
        var recentlyWatched = try recentlyWatched(maxCount: 100)
        // Remove any existing entry for this media
        recentlyWatched.removeAll { $0.mediaID == progress.mediaID }
        // Add new entry to beginning
        recentlyWatched.insert(progress, at: 0)
        // Keep only the most recent entries
        if recentlyWatched.count > 100 {
            recentlyWatched = Array(recentlyWatched[0..<100])
        }
        
        let recentData = try JSONEncoder().encode(recentlyWatched)
        userDefaults.set(recentData, forKey: recentlyWatchedKey)
    }
    
    public func clearProgress(for mediaID: MediaID) async throws {
        userDefaults.removeObject(forKey: progressKey(for: mediaID))
    }
    
    public func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress] {
        let data = userDefaults.data(forKey: recentlyWatchedKey)
        guard let data else { return [] }
        
        do {
            let progresses = try JSONDecoder().decode([PlaybackProgress].self, from: data)
            return Array(progresses.prefix(maxCount))
        } catch {
            // If we can't decode it, remove the key and return empty
            userDefaults.removeObject(forKey: recentlyWatchedKey)
            return []
        }
    }
    
    private func progressKey(for mediaID: MediaID) -> String {
        "progress_\(mediaID.kind.rawValue)_\(mediaID.value)"
    }
}