import Foundation
import SampleTVDomain
import Testing

@Suite struct WatchlistTests {
    @Test func getWatchlistReturnsEmptyArrayForNewProfile() async throws {
        let mockStore = MockWatchlistStore()

        let watchlist = try await GetWatchlist(store: mockStore)(for: "profile1")

        #expect(watchlist.isEmpty)
    }

    @Test func addAndRetrieveItems() async throws {
        let mockStore = MockWatchlistStore()
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

        try await mockStore.add(item, to: "profile1")
        let watchlist = try await GetWatchlist(store: mockStore)(for: "profile1")

        #expect(watchlist.count == 1)
        #expect(watchlist.first?.id.value == 123)
        #expect(watchlist.first?.title == "Test Movie")
    }

    @Test func toggleAddsItemIfNotPresent() async throws {
        let mockStore = MockWatchlistStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 456),
            title: "Another Movie",
            overview: "Another test movie"
        )

        let wasAdded = try await ToggleWatchlist(store: mockStore)(item, for: "profile1")

        #expect(wasAdded == true)

        let watchlist = try await GetWatchlist(store: mockStore)(for: "profile1")
        #expect(watchlist.count == 1)
        #expect(watchlist.first?.id.value == 456)
    }

    @Test func toggleRemovesItemIfPresent() async throws {
        let mockStore = MockWatchlistStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 789),
            title: "Yet Another Movie",
            overview: "Yet another test movie"
        )

        try await mockStore.add(item, to: "profile1")

        let wasAdded = try await ToggleWatchlist(store: mockStore)(item, for: "profile1")

        #expect(wasAdded == false)

        let watchlist = try await GetWatchlist(store: mockStore)(for: "profile1")
        #expect(watchlist.isEmpty)
    }

    @Test func isInWatchlistReturnsCorrectValue() async throws {
        let mockStore = MockWatchlistStore()
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 12345),
            title: "Check Movie",
            overview: "A movie to check"
        )

        try await mockStore.add(item, to: "profile1")

        let isInWatchlist = try await IsInWatchlist(store: mockStore)(item.id, for: "profile1")
        #expect(isInWatchlist == true)

        let nonExistentID = MediaID(kind: .movie, value: 99999)
        let isNotInWatchlist = try await IsInWatchlist(store: mockStore)(
            nonExistentID,
            for: "profile1"
        )
        #expect(isNotInWatchlist == false)
    }

    @Test func differentProfilesAreIsolated() async throws {
        let mockStore = MockWatchlistStore()
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

        try await mockStore.add(item1, to: "profile1")
        try await mockStore.add(item2, to: "profile2")

        let watchlist1 = try await GetWatchlist(store: mockStore)(for: "profile1")
        let watchlist2 = try await GetWatchlist(store: mockStore)(for: "profile2")

        #expect(watchlist1.count == 1)
        #expect(watchlist1.first?.id.value == 100)
        #expect(watchlist2.count == 1)
        #expect(watchlist2.first?.id.value == 200)
    }

    @Test func mediaKindIsolationForSameNumericID() async throws {
        let mockStore = MockWatchlistStore()
        let movie = MediaItem(id: MediaID(kind: .movie, value: 42), title: "Movie 42")
        let show = MediaItem(id: MediaID(kind: .tv, value: 42), title: "Show 42")

        try await mockStore.add(movie, to: "profile1")

        #expect(try await IsInWatchlist(store: mockStore)(movie.id, for: "profile1") == true)
        #expect(try await IsInWatchlist(store: mockStore)(show.id, for: "profile1") == false)

        try await mockStore.add(show, to: "profile1")
        let items = try await GetWatchlist(store: mockStore)(for: "profile1")
        #expect(items.count == 2)
    }
}

private actor MockWatchlistStore: WatchlistStore {
    private var itemsByProfile: [String: [MediaItem]] = [:]

    func items(for profileID: String) async throws -> [MediaItem] {
        itemsByProfile[profileID] ?? []
    }

    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool {
        (itemsByProfile[profileID] ?? []).contains { $0.id == mediaID }
    }

    func add(_ item: MediaItem, to profileID: String) async throws {
        var items = itemsByProfile[profileID] ?? []
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
        itemsByProfile[profileID] = items
    }

    func remove(_ mediaID: MediaID, from profileID: String) async throws {
        var items = itemsByProfile[profileID] ?? []
        items.removeAll { $0.id == mediaID }
        itemsByProfile[profileID] = items
    }

    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool {
        var items = itemsByProfile[profileID] ?? []
        if items.contains(where: { $0.id == item.id }) {
            items.removeAll { $0.id == item.id }
            itemsByProfile[profileID] = items
            return false
        }
        items.append(item)
        itemsByProfile[profileID] = items
        return true
    }
}
