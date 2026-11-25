import Foundation
import SampleTVDomain

/// UserDefaults-backed implementation of `PlaybackProgressStore`.
public actor UserDefaultsPlaybackProgressStore: PlaybackProgressStore {
    private let userDefaults: UserDefaults
    private let recentlyWatchedKey = "RecentlyWatched"

    public init(suiteName: String = "com.sampletv.progress") {
        self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress? {
        let key = progressKey(for: mediaID)
        guard let data = userDefaults.data(forKey: key) else { return nil }

        do {
            return try JSONDecoder().decode(PlaybackProgress.self, from: data)
        } catch {
            userDefaults.removeObject(forKey: key)
            return nil
        }
    }

    public func saveProgress(_ progress: PlaybackProgress) async throws {
        let data = try JSONEncoder().encode(progress)
        userDefaults.set(data, forKey: progressKey(for: progress.mediaID))

        var recent = try await recentlyWatched(maxCount: 100)
        recent.removeAll { $0.mediaID == progress.mediaID }
        recent.insert(progress, at: 0)
        if recent.count > 100 {
            recent = Array(recent.prefix(100))
        }

        let recentData = try JSONEncoder().encode(recent)
        userDefaults.set(recentData, forKey: recentlyWatchedKey)
    }

    public func clearProgress(for mediaID: MediaID) async throws {
        userDefaults.removeObject(forKey: progressKey(for: mediaID))

        var recent = try await recentlyWatched(maxCount: 100)
        recent.removeAll { $0.mediaID == mediaID }
        let recentData = try JSONEncoder().encode(recent)
        userDefaults.set(recentData, forKey: recentlyWatchedKey)
    }

    public func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress] {
        guard maxCount > 0, let data = userDefaults.data(forKey: recentlyWatchedKey) else { return [] }

        do {
            let progresses = try JSONDecoder().decode([PlaybackProgress].self, from: data)
            return Array(progresses.prefix(maxCount))
        } catch {
            userDefaults.removeObject(forKey: recentlyWatchedKey)
            return []
        }
    }

    private func progressKey(for mediaID: MediaID) -> String {
        "progress_\(mediaID.kind.rawValue)_\(mediaID.value)"
    }
}
