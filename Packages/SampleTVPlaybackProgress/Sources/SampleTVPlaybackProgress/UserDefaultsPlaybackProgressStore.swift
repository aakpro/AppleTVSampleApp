import Foundation
import SampleTVDomain

/// UserDefaults-backed implementation of `PlaybackProgressStore`.
public actor UserDefaultsPlaybackProgressStore: PlaybackProgressStore {
    private let userDefaults: UserDefaults

    public init(suiteName: String = "com.sampletv.progress") {
        self.userDefaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    public func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        let key = progressKey(for: mediaID, profileID: profileID)
        if let data = userDefaults.data(forKey: key) {
            return decodeProgress(data: data, key: key)
        }
        // Fallback read for legacy unscoped progress stored under default profile.
        if profileID == ViewerProfile.defaultID {
            let legacyKey = legacyProgressKey(for: mediaID)
            if let data = userDefaults.data(forKey: legacyKey) {
                return decodeProgress(data: data, key: legacyKey)
            }
        }
        return nil
    }

    public func saveProgress(_ progress: PlaybackProgress) async throws {
        let data = try JSONEncoder().encode(progress)
        userDefaults.set(data, forKey: progressKey(for: progress.mediaID, profileID: progress.profileID))

        var recent = try await recentlyWatched(for: progress.profileID, maxCount: 100)
        recent.removeAll { $0.mediaID == progress.mediaID }
        recent.insert(progress, at: 0)
        if recent.count > 100 {
            recent = Array(recent.prefix(100))
        }

        let recentData = try JSONEncoder().encode(recent)
        userDefaults.set(recentData, forKey: recentlyWatchedKey(for: progress.profileID))
    }

    public func clearProgress(for mediaID: MediaID, profileID: String) async throws {
        userDefaults.removeObject(forKey: progressKey(for: mediaID, profileID: profileID))
        if profileID == ViewerProfile.defaultID {
            userDefaults.removeObject(forKey: legacyProgressKey(for: mediaID))
        }

        var recent = try await recentlyWatched(for: profileID, maxCount: 100)
        recent.removeAll { $0.mediaID == mediaID }
        let recentData = try JSONEncoder().encode(recent)
        userDefaults.set(recentData, forKey: recentlyWatchedKey(for: profileID))
    }

    public func clearAllProgress(for profileID: String) async throws {
        let recent = try await recentlyWatched(for: profileID, maxCount: 100)
        for record in recent {
            userDefaults.removeObject(forKey: progressKey(for: record.mediaID, profileID: profileID))
            if profileID == ViewerProfile.defaultID {
                userDefaults.removeObject(forKey: legacyProgressKey(for: record.mediaID))
            }
        }
        userDefaults.removeObject(forKey: recentlyWatchedKey(for: profileID))
        if profileID == ViewerProfile.defaultID {
            userDefaults.removeObject(forKey: "RecentlyWatched")
        }
    }

    public func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] {
        guard maxCount > 0 else { return [] }
        let key = recentlyWatchedKey(for: profileID)
        if let data = userDefaults.data(forKey: key) {
            return decodeRecent(data: data, key: key, maxCount: maxCount)
        }
        if profileID == ViewerProfile.defaultID, let legacyData = userDefaults.data(forKey: "RecentlyWatched") {
            return decodeRecent(data: legacyData, key: "RecentlyWatched", maxCount: maxCount)
        }
        return []
    }

    private func decodeProgress(data: Data, key: String) -> PlaybackProgress? {
        do {
            return try JSONDecoder().decode(PlaybackProgress.self, from: data)
        } catch {
            userDefaults.removeObject(forKey: key)
            return nil
        }
    }

    private func decodeRecent(data: Data, key: String, maxCount: Int) -> [PlaybackProgress] {
        do {
            let progresses = try JSONDecoder().decode([PlaybackProgress].self, from: data)
            return Array(progresses.prefix(maxCount))
        } catch {
            userDefaults.removeObject(forKey: key)
            return []
        }
    }

    private func progressKey(for mediaID: MediaID, profileID: String) -> String {
        "progress_\(profileID)_\(mediaID.kind.rawValue)_\(mediaID.value)"
    }

    private func legacyProgressKey(for mediaID: MediaID) -> String {
        "progress_\(mediaID.kind.rawValue)_\(mediaID.value)"
    }

    private func recentlyWatchedKey(for profileID: String) -> String {
        "RecentlyWatched_\(profileID)"
    }
}
