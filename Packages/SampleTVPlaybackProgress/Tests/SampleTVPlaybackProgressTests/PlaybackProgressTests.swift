import Testing
import SampleTVDomain
import SampleTVPlaybackProgress

@Suite("Playback Progress Tests")
struct PlaybackProgressTests {
    
    @Test("PlaybackProgress isWatched property works correctly")
    func testIsWatched() {
        let movieID = MediaID(kind: .movie, value: 123)
        
        // Test case where position is less than 90% of duration
        let progress1 = PlaybackProgress(
            mediaID: movieID,
            position: 89,
            duration: 100
        )
        #expect(!progress1.isWatched)
        
        // Test case where position is at least 90% of duration (watched)
        let progress2 = PlaybackProgress(
            mediaID: movieID,
            position: 90,
            duration: 100
        )
        #expect(progress2.isWatched)
        
        // Test case where duration is zero
        let progress3 = PlaybackProgress(
            mediaID: movieID,
            position: 0,
            duration: 0
        )
        #expect(!progress3.isWatched)
    }
    
    @Test("UserDefaultsPlaybackProgressStore saves and loads progress correctly")
    func testUserDefaultsStore() async throws {
        let store = UserDefaultsPlaybackProgressStore()
        
        // Clear any existing data
        try await store.clearProgress(for: MediaID(kind: .movie, value: 123))
        
        // Create a sample progress record
        let movieID = MediaID(kind: .movie, value: 123)
        let progress = PlaybackProgress(
            mediaID: movieID,
            position: 300,
            duration: 600
        )
        
        // Save it
        try await store.saveProgress(progress)
        
        // Load it back
        let loadedProgress = try await store.loadProgress(for: movieID)
        #expect(loadedProgress != nil)
        guard let loaded = loadedProgress else { return }
        
        #expect(loaded.mediaID == movieID)
        #expect(loaded.position == 300)
        #expect(loaded.duration == 600)
        #expect(loaded.isWatched == false) // Less than 90% watched
    }
    
    @Test("UserDefaultsPlaybackProgressStore handles recently watched items")
    func testRecentlyWatched() async throws {
        let store = UserDefaultsPlaybackProgressStore()
        
        // Clear data first
        try await store.clearProgress(for: MediaID(kind: .movie, value: 1))
        try await store.clearProgress(for: MediaID(kind: .movie, value: 2))
        try await store.clearProgress(for: MediaID(kind: .movie, value: 3))
        
        // Create some sample progress records
        let movie1 = PlaybackProgress(
            mediaID: MediaID(kind: .movie, value: 1),
            position: 100,
            duration: 200
        )
        let movie2 = PlaybackProgress(
            mediaID: MediaID(kind: .movie, value: 2),
            position: 200,
            duration: 400
        )
        let movie3 = PlaybackProgress(
            mediaID: MediaID(kind: .movie, value: 3),
            position: 150,
            duration: 300
        )
        
        // Save them all in order (first one, second one, third one)
        try await store.saveProgress(movie1)
        try await store.saveProgress(movie2)
        try await store.saveProgress(movie3)
        
        // Check they were saved correctly and in order
        let recent = try await store.recentlyWatched(maxCount: 5)
        #expect(recent.count == 3)
        
        // Most recently added should be first (LIFO)
        #expect(recent[0].mediaID.value == 3)
        #expect(recent[1].mediaID.value == 2)
        #expect(recent[2].mediaID.value == 1)
    }
}