import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVDiscovery

private struct StubPlaybackProgressStore: PlaybackProgressStore {
    var progress: [PlaybackProgress]

    init(progress: [PlaybackProgress] = []) {
        self.progress = progress
    }

    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        progress.first { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {}
    func clearProgress(for mediaID: MediaID, profileID: String) async throws {}
    func clearAllProgress(for profileID: String) async throws {}
    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] { progress }
}

private struct StubResourceResolver: PlaybackResourceResolver {
    let resources: [PlayableResource]

    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        resources
    }
}

private actor StubWatchlistStore: WatchlistStore {
    private var itemsByProfile: [String: [MediaItem]]
    private let shouldThrow: Bool

    init(itemsByProfile: [String: [MediaItem]] = [:], shouldThrow: Bool = false) {
        self.itemsByProfile = itemsByProfile
        self.shouldThrow = shouldThrow
    }

    func items(for profileID: String) async throws -> [MediaItem] {
        if shouldThrow { throw MediaError.unknown }
        return itemsByProfile[profileID] ?? []
    }

    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool {
        if shouldThrow { throw MediaError.unknown }
        return (itemsByProfile[profileID] ?? []).contains { $0.id == mediaID }
    }

    func add(_ item: MediaItem, to profileID: String) async throws {
        if shouldThrow { throw MediaError.unknown }
        var items = itemsByProfile[profileID] ?? []
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
        itemsByProfile[profileID] = items
    }

    func remove(_ mediaID: MediaID, from profileID: String) async throws {
        if shouldThrow { throw MediaError.unknown }
        var items = itemsByProfile[profileID] ?? []
        items.removeAll { $0.id == mediaID }
        itemsByProfile[profileID] = items
    }

    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool {
        if shouldThrow { throw MediaError.unknown }
        if try await contains(item.id, in: profileID) {
            try await remove(item.id, from: profileID)
            return false
        } else {
            try await add(item, to: profileID)
            return true
        }
    }
}

@MainActor
struct DetailsPlaybackTests {
    private let item = MediaItem(
        id: MediaID(kind: .movie, value: 603),
        title: "The Matrix",
        overview: "A computer hacker learns about the true nature of reality.",
        releaseYear: 1999,
        genreIDs: [28, 878],
        rating: 8.7,
        posterPath: "/path.jpg"
    )

    @Test func resumeLabelReturnsPlayWhenNoProgress() {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            loadProgress: nil
        )
        #expect(model.resumeLabel == "Play")
    }

    @Test func resumeLabelReturnsPlayWhenWatched() async {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let store = StubPlaybackProgressStore(
            progress: [PlaybackProgress(mediaID: item.id, position: 950, duration: 1000)]
        )
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            loadProgress: LoadPlaybackProgress(store: store)
        )

        await model.load()
        #expect(model.resumeLabel == "Play")
    }

    @Test func resumeLabelReturnsResumeWithTimeFormatted() async {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let store = StubPlaybackProgressStore(
            progress: [PlaybackProgress(mediaID: item.id, position: 150, duration: 1000)]
        )
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            loadProgress: LoadPlaybackProgress(store: store)
        )

        await model.load()
        #expect(model.resumeLabel == "Resume 02:30")
    }

    @Test func resolvesFeatureAndTrailerResources() async throws {
        let featureURL = try #require(URL(string: "https://example.com/feature.mp4"))
        let trailerURL = try #require(URL(string: "https://example.com/trailer.mp4"))
        let feature = PlayableResource(url: featureURL, kind: .feature, title: "Feature", trackProgress: true)
        let trailer = PlayableResource(url: trailerURL, kind: .trailer, title: "Trailer", trackProgress: false)

        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let resolver = StubResourceResolver(resources: [feature, trailer])
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            resolveResources: ResolvePlaybackResources(resolver: resolver)
        )

        await model.load()

        let resolvedFeature = try await model.resolvePlayableResource(kind: .feature)
        let resolvedTrailer = try await model.resolvePlayableResource(kind: .trailer)
        let allResources = try await model.getPlayableResources()

        #expect(resolvedFeature == feature)
        #expect(resolvedTrailer == trailer)
        #expect(allResources.count == 2)
    }

    @Test func loadInitialWatchlistState() async {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let watchlistStore = StubWatchlistStore(itemsByProfile: ["main": [item]])
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            isInWatchlist: IsInWatchlist(store: watchlistStore)
        )

        await model.load()
        #expect(model.isInWatchlist == true)
    }

    @Test func loadInitialWatchlistStateIsScopedToProfile() async {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let watchlistStore = StubWatchlistStore(itemsByProfile: ["main": [item]])
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            isInWatchlist: IsInWatchlist(store: watchlistStore),
            profileID: "kids"
        )

        await model.load()
        #expect(model.isInWatchlist == false)
    }

    @Test func toggleWatchlistAddsAndRemovesItem() async throws {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let watchlistStore = StubWatchlistStore()
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            isInWatchlist: IsInWatchlist(store: watchlistStore),
            toggleWatchlist: ToggleWatchlist(store: watchlistStore),
            profileID: "kids"
        )

        await model.load()
        #expect(model.isInWatchlist == false)

        await model.toggleWatchlist()
        #expect(model.isInWatchlist == true)
        #expect(try await watchlistStore.contains(item.id, in: "kids") == true)
        #expect(try await watchlistStore.contains(item.id, in: "main") == false)

        await model.toggleWatchlist()
        #expect(model.isInWatchlist == false)
        #expect(try await watchlistStore.contains(item.id, in: "kids") == false)
    }

    @Test func loadKeepsDetailsWhenWatchlistStoreThrows() async {
        let details = MediaDetails(item: item)
        let repository = PlaybackDetailsRepository(details: details)
        let watchlistStore = StubWatchlistStore(shouldThrow: true)
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            isInWatchlist: IsInWatchlist(store: watchlistStore)
        )

        await model.load()
        #expect(model.state == .loaded(details))
        #expect(model.isInWatchlist == false)
    }

    @Test func toggleWatchlistKeepsStateWhenStoreThrows() async {
        let repository = PlaybackDetailsRepository(details: MediaDetails(item: item))
        let watchlistStore = StubWatchlistStore(shouldThrow: true)
        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            isInWatchlist: IsInWatchlist(store: watchlistStore),
            toggleWatchlist: ToggleWatchlist(store: watchlistStore)
        )

        await model.load()
        #expect(model.isInWatchlist == false)

        await model.toggleWatchlist()
        #expect(model.isInWatchlist == false)
    }

    @Test func loadSetsShouldAutoplayTrailerFromUserPreferences() async throws {
        let trailerURL = try #require(URL(string: "https://example.com/trailer.m3u8"))
        let trailer = PlayableResource(
            url: trailerURL,
            kind: .trailer,
            title: "Trailer",
            trackProgress: false
        )
        let details = MediaDetails(
            item: item,
            videos: [MediaVideo(id: "v1", kind: .trailer, name: "Official", site: "YouTube", key: "k", language: "en")]
        )
        let repo = PlaybackDetailsRepository(details: details)

        let enabledVM = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repo),
            resolveResources: ResolvePlaybackResources(resolver: StubResourceResolver(resources: [trailer])),
            getPreferences: GetUserPreferences(repository: StubPreferencesProfileRepository(autoplayTrailers: true))
        )
        await enabledVM.load()
        #expect(enabledVM.shouldAutoplayTrailer == true)

        let disabledVM = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repo),
            resolveResources: ResolvePlaybackResources(resolver: StubResourceResolver(resources: [trailer])),
            getPreferences: GetUserPreferences(repository: StubPreferencesProfileRepository(autoplayTrailers: false))
        )
        await disabledVM.load()
        #expect(disabledVM.shouldAutoplayTrailer == false)
    }

    @Test func resolvePlayableResourceAndGetPlayableResourcesReturnResolvedStreams() async throws {
        let featureURL = try #require(URL(string: "https://example.com/feature.m3u8"))
        let trailerURL = try #require(URL(string: "https://example.com/trailer.m3u8"))
        let feature = PlayableResource(url: featureURL, kind: .feature, title: "Feature", trackProgress: true)
        let trailer = PlayableResource(url: trailerURL, kind: .trailer, title: "Trailer", trackProgress: false)

        let model = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: PlaybackDetailsRepository(details: MediaDetails(item: item))),
            resolveResources: ResolvePlaybackResources(resolver: StubResourceResolver(resources: [feature, trailer]))
        )
        await model.load()

        let resolvedFeature = try await model.resolvePlayableResource(kind: .feature)
        #expect(resolvedFeature == feature)
        let all = try await model.getPlayableResources()
        #expect(all == [feature, trailer])
    }
}

private struct StubPreferencesProfileRepository: ProfileRepository {
    let autoplayTrailers: Bool

    func currentProfile() async throws -> ViewerProfile { ViewerProfile(id: "main", name: "Main", isMain: true) }
    func profiles() async throws -> [ViewerProfile] { [try await currentProfile()] }
    func preferences(for profileID: String) async throws -> UserPreferences {
        UserPreferences(defaultKind: .movie, autoplayTrailers: autoplayTrailers)
    }
    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {}
    func switchProfile(to profileID: String) async throws {}
}

private struct PlaybackDetailsRepository: MediaRepository {
    let details: MediaDetails

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { details }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}
