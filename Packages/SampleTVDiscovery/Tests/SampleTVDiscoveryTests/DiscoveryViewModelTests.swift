import SampleTVDomain
import Testing
@testable import SampleTVDiscovery

private struct StubRepository: MediaRepository {
    var result: Result<ResultPage<MediaItem>, MediaError>
    var detailsByID: [MediaID: MediaDetails] = [:]

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func details(of id: MediaID) async throws -> MediaDetails {
        if let details = detailsByID[id] { return details }
        throw MediaError.notFound
    }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

private actor StubProgressStore: PlaybackProgressStore {
    var recent: [PlaybackProgress]

    init(recent: [PlaybackProgress] = []) {
        self.recent = recent
    }

    func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress? {
        recent.first { $0.mediaID == mediaID }
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {
        recent.removeAll { $0.mediaID == progress.mediaID }
        recent.insert(progress, at: 0)
    }

    func clearProgress(for mediaID: MediaID) async throws {
        recent.removeAll { $0.mediaID == mediaID }
    }

    func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress] {
        Array(recent.prefix(maxCount))
    }
}

@MainActor
struct DiscoveryViewModelTests {
    private let item = MediaItem(id: MediaID(kind: .tv, value: 1), title: "Show")

    @Test func reloadPublishesItems() async {
        let page = ResultPage(items: [item], page: 1, totalPages: 2)
        let model = DiscoveryViewModel(discover: DiscoverMedia(repository: StubRepository(result: .success(page))))
        await model.reload()
        #expect(model.state == .loaded([item]))
        #expect(model.canLoadMore)
    }

    @Test func failureSurfacesDomainError() async {
        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: StubRepository(result: .failure(.offline)))
        )
        await model.reload()
        #expect(model.state == .failed(.offline))
    }

    @Test func loadContinueWatchingResolvesUnfinishedItemsInOrder() async {
        let loadedItem = MediaItem(id: MediaID(kind: .tv, value: 1), title: "Show 1")
        let fetchedItem = MediaItem(id: MediaID(kind: .movie, value: 2), title: "Movie 2")
        let watchedItem = MediaItem(id: MediaID(kind: .movie, value: 3), title: "Movie 3")

        let repo = StubRepository(
            result: .success(ResultPage(items: [loadedItem], page: 1, totalPages: 1)),
            detailsByID: [
                fetchedItem.id: MediaDetails(item: fetchedItem),
                watchedItem.id: MediaDetails(item: watchedItem)
            ]
        )
        let store = StubProgressStore(recent: [
            PlaybackProgress(mediaID: fetchedItem.id, position: 120, duration: 600),
            PlaybackProgress(mediaID: watchedItem.id, position: 580, duration: 600), // >= 90%, excluded
            PlaybackProgress(mediaID: loadedItem.id, position: 45, duration: 600),
            PlaybackProgress(mediaID: MediaID(kind: .movie, value: 999), position: 30, duration: 600) // missing details
        ])

        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: repo),
            getDetails: GetMediaDetails(repository: repo),
            progressStore: store
        )

        await model.reload()
        await model.loadContinueWatching()

        #expect(model.continueWatchingItems == [fetchedItem, loadedItem])
    }
}

@MainActor
struct DetailsViewModelTests {
    @Test func loadPublishesDetails() async {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let details = MediaDetails(item: item, genres: [Genre(id: 28, name: "Action")])
        let repository = DetailsRepository(details: details)
        let model = DetailsViewModel(item: item, getDetails: GetMediaDetails(repository: repository))
        await model.load()
        #expect(model.state == .loaded(details))
    }
}

private struct DetailsRepository: MediaRepository {
    let details: MediaDetails
    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { details }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}
