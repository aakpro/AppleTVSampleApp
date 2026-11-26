import Foundation
import SampleTVDomain
import SampleTVPlaybackProgress
import Testing

@Suite("Playback Progress Tests")
struct PlaybackProgressTests {
    private func makeStore() -> UserDefaultsPlaybackProgressStore {
        let suite = "com.sampletv.progress.tests.\(UUID().uuidString)"
        UserDefaults.standard.removePersistentDomain(forName: suite)
        return UserDefaultsPlaybackProgressStore(suiteName: suite)
    }

    @Test("PlaybackProgress isWatched property works correctly")
    func testIsWatched() {
        let movieID = MediaID(kind: .movie, value: 123)

        let progress1 = PlaybackProgress(mediaID: movieID, position: 89, duration: 100)
        #expect(!progress1.isWatched)

        let progress2 = PlaybackProgress(mediaID: movieID, position: 90, duration: 100)
        #expect(progress2.isWatched)

        let progress3 = PlaybackProgress(mediaID: movieID, position: 0, duration: 0)
        #expect(!progress3.isWatched)
    }

    @Test("UserDefaultsPlaybackProgressStore saves, loads, and clears progress")
    func testUserDefaultsStore() async throws {
        let store = makeStore()
        let movieID = MediaID(kind: .movie, value: 123)
        let progress = PlaybackProgress(mediaID: movieID, position: 300, duration: 600)

        try await store.saveProgress(progress)

        let loaded = try await store.loadProgress(for: movieID)
        #expect(loaded?.mediaID == movieID)
        #expect(loaded?.position == 300)
        #expect(loaded?.duration == 600)
        #expect(loaded?.isWatched == false)

        try await store.clearProgress(for: movieID)
        let cleared = try await store.loadProgress(for: movieID)
        #expect(cleared == nil)
    }

    @Test("UserDefaultsPlaybackProgressStore orders recently watched items LIFO")
    func testRecentlyWatched() async throws {
        let store = makeStore()

        let movie1 = PlaybackProgress(mediaID: MediaID(kind: .movie, value: 1), position: 100, duration: 200)
        let movie2 = PlaybackProgress(mediaID: MediaID(kind: .movie, value: 2), position: 200, duration: 400)
        let movie3 = PlaybackProgress(mediaID: MediaID(kind: .movie, value: 3), position: 150, duration: 300)

        try await store.saveProgress(movie1)
        try await store.saveProgress(movie2)
        try await store.saveProgress(movie3)

        let recent = try await store.recentlyWatched(maxCount: 5)
        #expect(recent.count == 3)
        #expect(recent[0].mediaID.value == 3)
        #expect(recent[1].mediaID.value == 2)
        #expect(recent[2].mediaID.value == 1)
    }

    @Test("UserDefaultsPlaybackProgressStore profileID isolation")
    func testProfileIDIsolation() async throws {
        let store = makeStore()
        let movieID = MediaID(kind: .movie, value: 123)

        // Save progress for one profile
        let progressMain = PlaybackProgress(mediaID: movieID, position: 100, duration: 600, profileID: "main")
        try await store.saveProgress(progressMain)

        // Try to get it from different profile - should not exist
        let loaded = try await store.loadProgress(for: movieID, profileID: "kids")
        #expect(loaded == nil)
    }

    @Test("UserDefaultsPlaybackProgressStore clearAllProgress")
    func testClearAllProgress() async throws {
        let store = makeStore()
        let movieID1 = MediaID(kind: .movie, value: 123)
        let movieID2 = MediaID(kind: .movie, value: 456)

        // Save progress for one profile
        let progress1 = PlaybackProgress(mediaID: movieID1, position: 100, duration: 600, profileID: "main")
        let progress2 = PlaybackProgress(mediaID: movieID2, position: 200, duration: 600, profileID: "main")
        try await store.saveProgress(progress1)
        try await store.saveProgress(progress2)

        // Clear all for that profile
        try await store.clearAllProgress(for: "main")

        // Check both are cleared
        let loaded1 = try await store.loadProgress(for: movieID1, profileID: "main")
        let loaded2 = try await store.loadProgress(for: movieID2, profileID: "main")
        #expect(loaded1 == nil)
        #expect(loaded2 == nil)
    }
}
