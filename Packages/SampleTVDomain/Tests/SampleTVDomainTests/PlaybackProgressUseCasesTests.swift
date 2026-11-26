import Foundation
import SampleTVDomain
import Testing

@Suite("PlaybackProgress Use Cases Tests")
struct PlaybackProgressUseCasesTests {
    @Test func playbackProgressDefaultsToViewerProfileDefaultID() {
        let progress = PlaybackProgress(mediaID: .init(kind: .movie, value: 123), position: 0, duration: 0)
        #expect(progress.profileID == ViewerProfile.defaultID)
    }

    @Test func playbackProgressDecodableFallbackWhenProfileIDMissing() throws {
        let json = """
        {
            "mediaID": {
                "kind": "movie",
                "value": 123
            },
            "position": 42,
            "duration": 100,
            "updatedAt": 0
        }
        """
        let progress = try JSONDecoder().decode(PlaybackProgress.self, from: Data(json.utf8))
        #expect(progress.profileID == ViewerProfile.defaultID)
        #expect(progress.position == 42)
    }

    @Test func loadPlaybackProgress() async throws {
        let progressStore = StubProgressStore()
        let progress = PlaybackProgress(mediaID: .init(kind: .movie, value: 123), position: 100, duration: 600)
        try await progressStore.saveProgress(progress)

        let loadProgress = LoadPlaybackProgress(store: progressStore)
        let loaded = try await loadProgress(for: progress.mediaID, profileID: ViewerProfile.defaultID)
        #expect(loaded?.position == 100)
    }

    @Test func savePlaybackProgress() async throws {
        let progressStore = StubProgressStore()
        let progress = PlaybackProgress(mediaID: .init(kind: .movie, value: 123), position: 200, duration: 600)

        let saveProgress = SavePlaybackProgress(store: progressStore)
        try await saveProgress(progress)

        let loaded = try await progressStore.loadProgress(
            for: progress.mediaID,
            profileID: ViewerProfile.defaultID
        )
        #expect(loaded?.position == 200)
    }

    @Test func clearWatchHistory() async throws {
        let progressStore = StubProgressStore()
        let progress = PlaybackProgress(mediaID: .init(kind: .movie, value: 123), position: 100, duration: 600)
        try await progressStore.saveProgress(progress)

        let clearWatchHistory = ClearWatchHistory(store: progressStore)
        try await clearWatchHistory(for: ViewerProfile.defaultID)

        let loaded = try await progressStore.loadProgress(
            for: progress.mediaID,
            profileID: ViewerProfile.defaultID
        )
        #expect(loaded == nil)
    }

    @Test func getContinueWatchingFiltersByKindAndFetchesMissingDetails() async throws {
        let movie = MediaItem(id: .init(kind: .movie, value: 123), title: "Movie 123")
        let show = MediaItem(id: .init(kind: .tv, value: 456), title: "Show 456")
        let watchedMovie = MediaItem(id: .init(kind: .movie, value: 789), title: "Watched 789")

        let progressStore = StubProgressStore()
        try await progressStore.saveProgress(
            PlaybackProgress(mediaID: movie.id, position: 100, duration: 600)
        )
        try await progressStore.saveProgress(
            PlaybackProgress(mediaID: show.id, position: 200, duration: 600)
        )
        try await progressStore.saveProgress(
            PlaybackProgress(mediaID: watchedMovie.id, position: 590, duration: 600)
        )

        let mediaRepository = StubMediaRepository(itemsByID: [show.id: show])
        let getContinueWatching = GetContinueWatching(
            progressStore: progressStore,
            mediaRepository: mediaRepository
        )

        let allItems = try await getContinueWatching(
            for: ViewerProfile.defaultID,
            knownItems: [movie.id: movie]
        )
        #expect(allItems.map(\.item) == [show, movie])

        let tvOnly = try await getContinueWatching(
            for: ViewerProfile.defaultID,
            kind: .tv
        )
        #expect(tvOnly.map(\.item) == [show])
    }

    @Test func resolvePlaybackResourcesFindsRequestedKind() async throws {
        let featureURL = try #require(URL(string: "https://example.com/feature.m3u8"))
        let trailerURL = try #require(URL(string: "https://example.com/trailer.m3u8"))
        let resolver = StubResourceResolver(resources: [
            PlayableResource(url: featureURL, kind: .feature, title: "Feature", trackProgress: true),
            PlayableResource(url: trailerURL, kind: .trailer, title: "Trailer", trackProgress: false)
        ])

        let resolveResources = ResolvePlaybackResources(resolver: resolver)
        let all = try await resolveResources(.init(kind: .movie, value: 123), genreIDs: [28])
        #expect(all.count == 2)

        let trailer = try await resolveResources.resolveFirst(
            .init(kind: .movie, value: 123),
            genreIDs: [28],
            kind: .trailer
        )
        #expect(trailer?.url == trailerURL)
    }

    @Test func savePlaybackProgressSkipsPositionsBelowFiveSeconds() async throws {
        let progressStore = StubProgressStore()
        let saveProgress = SavePlaybackProgress(store: progressStore)

        let lowPositionProgress = PlaybackProgress(
            mediaID: .init(kind: .movie, value: 123),
            position: 4.5,
            duration: 600
        )
        try await saveProgress(lowPositionProgress)

        let loaded = try await progressStore.loadProgress(
            for: lowPositionProgress.mediaID,
            profileID: ViewerProfile.defaultID
        )
        #expect(loaded == nil)

        let validPositionProgress = PlaybackProgress(
            mediaID: .init(kind: .movie, value: 123),
            position: 5.0,
            duration: 600
        )
        try await saveProgress(validPositionProgress)

        let loaded2 = try await progressStore.loadProgress(
            for: validPositionProgress.mediaID,
            profileID: ViewerProfile.defaultID
        )
        #expect(loaded2?.position == 5.0)
    }
}

private actor StubProgressStore: PlaybackProgressStore {
    private var records: [PlaybackProgress] = []

    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        records.first { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {
        records.removeAll { $0.mediaID == progress.mediaID && $0.profileID == progress.profileID }
        records.insert(progress, at: 0)
    }

    func clearProgress(for mediaID: MediaID, profileID: String) async throws {
        records.removeAll { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func clearAllProgress(for profileID: String) async throws {
        records.removeAll { $0.profileID == profileID }
    }

    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] {
        Array(records.filter { $0.profileID == profileID }.prefix(maxCount))
    }
}

private struct StubMediaRepository: MediaRepository {
    let itemsByID: [MediaID: MediaItem]

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails {
        guard let item = itemsByID[id] else { throw MediaError.notFound }
        return MediaDetails(item: item)
    }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

private struct StubResourceResolver: PlaybackResourceResolver {
    let resources: [PlayableResource]

    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        resources
    }
}
