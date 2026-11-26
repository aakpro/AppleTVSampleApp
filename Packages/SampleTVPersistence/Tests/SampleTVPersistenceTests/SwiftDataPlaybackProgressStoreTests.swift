import Foundation
import SampleTVDomain
import SwiftData
import Testing
@testable import SampleTVPersistence

@Suite("SwiftDataPlaybackProgressStore Tests")
struct SwiftDataPlaybackProgressStoreTests {
    private func makeStore() throws -> SwiftDataPlaybackProgressStore {
        try SwiftDataPlaybackProgressStore(inMemory: true)
    }

    @Test func saveAndLoadProgressRoundTrip() async throws {
        let store = try makeStore()
        let movieID = MediaID(kind: .movie, value: 123)
        let progress = PlaybackProgress(mediaID: movieID, position: 300, duration: 600)

        try await store.saveProgress(progress)

        let loaded = try await store.loadProgress(for: movieID, profileID: ViewerProfile.defaultID)
        #expect(loaded?.mediaID == movieID)
        #expect(loaded?.position == 300)
        #expect(loaded?.duration == 600)
        #expect(loaded?.isWatched == false)
    }

    @Test func saveProgressUpsertsExistingRecord() async throws {
        let store = try makeStore()
        let movieID = MediaID(kind: .movie, value: 123)

        let initial = PlaybackProgress(mediaID: movieID, position: 100, duration: 600)
        try await store.saveProgress(initial)

        let updated = PlaybackProgress(mediaID: movieID, position: 300, duration: 600)
        try await store.saveProgress(updated)

        let loaded = try await store.loadProgress(for: movieID, profileID: ViewerProfile.defaultID)
        #expect(loaded?.position == 300)
        #expect(loaded?.duration == 600)
    }

    @Test func profileIDIsolation() async throws {
        let store = try makeStore()
        let movieID = MediaID(kind: .movie, value: 123)

        let progress = PlaybackProgress(mediaID: movieID, position: 100, duration: 600, profileID: "main")
        try await store.saveProgress(progress)

        let loadedForKids = try await store.loadProgress(for: movieID, profileID: "kids")
        #expect(loadedForKids == nil)
    }

    @Test func clearProgress() async throws {
        let store = try makeStore()
        let movieID = MediaID(kind: .movie, value: 123)

        let progress = PlaybackProgress(mediaID: movieID, position: 100, duration: 600)
        try await store.saveProgress(progress)

        try await store.clearProgress(for: movieID, profileID: ViewerProfile.defaultID)

        let loaded = try await store.loadProgress(for: movieID, profileID: ViewerProfile.defaultID)
        #expect(loaded == nil)
    }

    @Test func clearAllProgressForProfile() async throws {
        let store = try makeStore()
        let movieID1 = MediaID(kind: .movie, value: 123)
        let movieID2 = MediaID(kind: .movie, value: 456)

        try await store.saveProgress(
            PlaybackProgress(mediaID: movieID1, position: 100, duration: 600, profileID: "main")
        )
        try await store.saveProgress(
            PlaybackProgress(mediaID: movieID2, position: 200, duration: 600, profileID: "main")
        )
        try await store.saveProgress(
            PlaybackProgress(mediaID: movieID1, position: 50, duration: 600, profileID: "kids")
        )

        try await store.clearAllProgress(for: "main")

        #expect(try await store.loadProgress(for: movieID1, profileID: "main") == nil)
        #expect(try await store.loadProgress(for: movieID2, profileID: "main") == nil)
        #expect(try await store.loadProgress(for: movieID1, profileID: "kids")?.position == 50)
    }

    @Test func recentlyWatchedOrderedByUpdatedAtDescending() async throws {
        let store = try makeStore()
        let movie1 = PlaybackProgress(
            mediaID: MediaID(kind: .movie, value: 1),
            position: 100,
            duration: 200,
            updatedAt: Date(timeIntervalSince1970: 200),
            profileID: "main"
        )
        let movie2 = PlaybackProgress(
            mediaID: MediaID(kind: .movie, value: 2),
            position: 200,
            duration: 400,
            updatedAt: Date(timeIntervalSince1970: 300),
            profileID: "main"
        )
        let movie3 = PlaybackProgress(
            mediaID: MediaID(kind: .movie, value: 3),
            position: 150,
            duration: 300,
            updatedAt: Date(timeIntervalSince1970: 100),
            profileID: "main"
        )

        try await store.saveProgress(movie3)
        try await store.saveProgress(movie1)
        try await store.saveProgress(movie2)

        let recent = try await store.recentlyWatched(for: "main", maxCount: 5)
        #expect(recent.map(\.mediaID.value) == [2, 1, 3])
    }

    @Test func storesShareSinglePersistenceContainer() async throws {
        let container = try PersistenceContainer.makeModelContainer(inMemory: true)
        let profileRepo = SwiftDataProfileRepository(modelContainer: container)
        let watchlistStore = SwiftDataWatchlistStore(modelContainer: container)
        let progressStore = SwiftDataPlaybackProgressStore(modelContainer: container)

        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let profile = try await profileRepo.currentProfile()
        try await watchlistStore.add(item, to: profile.id)
        try await progressStore.saveProgress(
            PlaybackProgress(mediaID: item.id, position: 120, duration: 600, profileID: profile.id)
        )

        #expect(try await watchlistStore.items(for: profile.id) == [item])
        #expect(try await progressStore.loadProgress(for: item.id, profileID: profile.id)?.position == 120)
    }
}
