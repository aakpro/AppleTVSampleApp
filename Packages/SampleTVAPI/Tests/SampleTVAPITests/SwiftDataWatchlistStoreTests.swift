import Foundation
import SampleTVDomain
import SwiftData
import Testing
@testable import SampleTVAPI

@Suite struct SwiftDataWatchlistStoreTests {
    private func makeStore() throws -> SwiftDataWatchlistStore {
        try SwiftDataWatchlistStore(inMemory: true)
    }

    @Test func itemsReturnsEmptyArrayForNewProfile() async throws {
        let store = try makeStore()

        let items = try await store.items(for: "profile1")

        #expect(items.isEmpty)
    }

    @Test func addAndRetrieveItems() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 123),
            title: "Test Movie",
            overview: "A test movie",
            releaseYear: 2023,
            genreIDs: [1, 2],
            rating: 8.5,
            posterPath: "/test.jpg",
            backdropPath: "/test-bg.jpg"
        )

        try await store.add(item, to: "profile1")
        let items = try await store.items(for: "profile1")

        #expect(items.count == 1)
        #expect(items.first?.id == MediaID(kind: .movie, value: 123))
        #expect(items.first?.title == "Test Movie")
        #expect(items.first?.overview == "A test movie")
        #expect(items.first?.releaseYear == 2023)
        #expect(items.first?.genreIDs == [1, 2])
        #expect(items.first?.rating == 8.5)
        #expect(items.first?.posterPath == "/test.jpg")
        #expect(items.first?.backdropPath == "/test-bg.jpg")
    }

    @Test func nilOptionalFieldsRoundTrip() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .tv, value: 321),
            title: "Minimal Show"
        )

        try await store.add(item, to: "profile1")
        let items = try await store.items(for: "profile1")

        #expect(items == [item])
    }

    @Test func addSameItemTwiceIsIdempotent() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 111),
            title: "Duplicate Test"
        )

        try await store.add(item, to: "profile1")
        try await store.add(item, to: "profile1")

        let items = try await store.items(for: "profile1")
        #expect(items.count == 1)
    }

    @Test func containsReturnsCorrectValue() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 456),
            title: "Another Movie",
            overview: "Another test movie"
        )

        try await store.add(item, to: "profile1")

        let containsItem = try await store.contains(item.id, in: "profile1")
        #expect(containsItem == true)

        let nonExistentItem = MediaID(kind: .movie, value: 99999)
        let doesNotContain = try await store.contains(nonExistentItem, in: "profile1")
        #expect(doesNotContain == false)
    }

    @Test func removeItem() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 789),
            title: "To Be Removed",
            overview: "This will be removed"
        )

        try await store.add(item, to: "profile1")
        try await store.remove(item.id, from: "profile1")
        let items = try await store.items(for: "profile1")

        #expect(items.isEmpty)
    }

    @Test func toggleAddsItemIfNotPresent() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 987),
            title: "Toggle Movie",
            overview: "A movie to test toggle"
        )

        let wasAdded = try await store.toggle(item, for: "profile1")

        #expect(wasAdded == true)

        let items = try await store.items(for: "profile1")
        #expect(items.count == 1)
        #expect(items.first?.id.value == 987)
    }

    @Test func toggleRemovesItemIfPresent() async throws {
        let store = try makeStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 654),
            title: "Toggle Movie",
            overview: "A movie to test toggle"
        )

        try await store.add(item, to: "profile1")

        let wasAdded = try await store.toggle(item, for: "profile1")

        #expect(wasAdded == false)

        let items = try await store.items(for: "profile1")
        #expect(items.isEmpty)
    }

    @Test func profileIsolation() async throws {
        let store = try makeStore()
        let item1 = MediaItem(
            id: MediaID(kind: .movie, value: 100),
            title: "Profile 1 Movie",
            overview: "A movie for profile 1"
        )
        let item2 = MediaItem(
            id: MediaID(kind: .tv, value: 200),
            title: "Profile 2 Series",
            overview: "A series for profile 2"
        )

        try await store.add(item1, to: "profile1")
        try await store.add(item2, to: "profile2")

        let items1 = try await store.items(for: "profile1")
        let items2 = try await store.items(for: "profile2")

        #expect(items1.count == 1)
        #expect(items1.first?.id.value == 100)
        #expect(items2.count == 1)
        #expect(items2.first?.id.value == 200)
    }

    @Test func mediaKindIsolationForSameNumericID() async throws {
        let store = try makeStore()
        let movie = MediaItem(id: MediaID(kind: .movie, value: 42), title: "Movie 42")
        let show = MediaItem(id: MediaID(kind: .tv, value: 42), title: "Show 42")

        try await store.add(movie, to: "profile1")

        #expect(try await store.contains(movie.id, in: "profile1") == true)
        #expect(try await store.contains(show.id, in: "profile1") == false)

        try await store.add(show, to: "profile1")
        try await store.remove(movie.id, from: "profile1")

        let remaining = try await store.items(for: "profile1")
        #expect(remaining == [show])
    }

    @Test func orderingIsByAddedAtDesc() async throws {
        let store = try makeStore()
        let item1 = MediaItem(
            id: MediaID(kind: .movie, value: 1),
            title: "First Item",
            overview: "The first item added"
        )
        let item2 = MediaItem(
            id: MediaID(kind: .movie, value: 2),
            title: "Second Item",
            overview: "The second item added"
        )

        try await store.add(item1, to: "profile1")
        try await Task.sleep(for: .milliseconds(20))
        try await store.add(item2, to: "profile1")

        let items = try await store.items(for: "profile1")

        #expect(items.count == 2)
        #expect(items.first?.id.value == 2)
        #expect(items.last?.id.value == 1)
    }
}
