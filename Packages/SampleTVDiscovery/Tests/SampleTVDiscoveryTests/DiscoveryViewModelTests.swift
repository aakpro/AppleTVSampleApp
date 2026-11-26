import SampleTVDomain
import Testing
@testable import SampleTVDiscovery

private struct StubRepository: MediaRepository {
    var result: Result<ResultPage<MediaItem>, MediaError>
    var genresResult: [Genre] = []
    var detailsByID: [MediaID: MediaDetails] = [:]

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func details(of id: MediaID) async throws -> MediaDetails {
        if let details = detailsByID[id] { return details }
        throw MediaError.notFound
    }
    func genres(for kind: MediaKind) async throws -> [Genre] { genresResult }
}

private actor StubProgressStore: PlaybackProgressStore {
    var recent: [PlaybackProgress]

    init(recent: [PlaybackProgress] = []) {
        self.recent = recent
    }

    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        recent.first { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {
        recent.removeAll { $0.mediaID == progress.mediaID && $0.profileID == progress.profileID }
        recent.insert(progress, at: 0)
    }

    func clearProgress(for mediaID: MediaID, profileID: String) async throws {
        recent.removeAll { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func clearAllProgress(for profileID: String) async throws {
        recent.removeAll { $0.profileID == profileID }
    }

    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] {
        Array(recent.filter { $0.profileID == profileID }.prefix(maxCount))
    }
}

@MainActor
struct DiscoveryViewModelTests {
    private let item = MediaItem(id: MediaID(kind: .tv, value: 1), title: "Show")

    @Test func reloadPublishesItemsAndPagination() async {
        let page = ResultPage(items: [item], page: 1, totalPages: 2)
        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: StubRepository(result: .success(page))),
            filter: MediaFilter(kind: .tv)
        )
        await model.reload()
        #expect(model.state == .loaded([MediaShelf(id: "popular-tv", title: "Popular TV Shows", items: [item])]))
        #expect(model.canLoadMore)
    }

    @Test func reloadWithGetDiscoveryShelvesLoadsMultipleShelves() async {
        let page = ResultPage(items: [item], page: 1, totalPages: 1)
        let repo = StubRepository(result: .success(page), genresResult: [Genre(id: 18, name: "Drama")])
        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: repo),
            getDiscoveryShelves: GetDiscoveryShelves(repository: repo),
            filter: MediaFilter(kind: .movie)
        )
        await model.reload()
        if case .loaded(let shelves) = model.state {
            #expect(shelves.map(\.title) == ["Popular", "Top Rated", "New Releases", "Drama"])
        } else {
            Issue.record("Expected loaded state")
        }
    }

    @Test func failureSurfacesDomainError() async {
        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: StubRepository(result: .failure(.offline)))
        )
        await model.reload()
        #expect(model.state == .failed(.offline))
    }

    @Test func loadContinueWatchingResolvesUnfinishedItemsAndProgress() async {
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
            PlaybackProgress(mediaID: watchedItem.id, position: 580, duration: 600),
            PlaybackProgress(mediaID: loadedItem.id, position: 45, duration: 600),
            PlaybackProgress(mediaID: MediaID(kind: .movie, value: 999), position: 30, duration: 600)
        ])

        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: repo),
            getContinueWatching: GetContinueWatching(progressStore: store, mediaRepository: repo)
        )

        await model.reload()
        await model.loadContinueWatching()

        #expect(model.continueWatchingItems == [fetchedItem])
        #expect(model.progressByID[fetchedItem.id] == 0.2)
    }

    @Test func loadContinueWatchingResolvesUnfinishedItemsAndProgressFiltersByKind() async {
        let movieItem = MediaItem(id: MediaID(kind: .movie, value: 1), title: "Movie Show")
        let movieProgress = PlaybackProgress(mediaID: movieItem.id, position: 45, duration: 600)

        let tvItem = MediaItem(id: MediaID(kind: .tv, value: 2), title: "TV Show")
        let tvProgress = PlaybackProgress(mediaID: tvItem.id, position: 120, duration: 600)

        let repo = StubRepository(
            result: .success(ResultPage(items: [], page: 1, totalPages: 1)),
            detailsByID: [
                movieItem.id: MediaDetails(item: movieItem),
                tvItem.id: MediaDetails(item: tvItem)
            ]
        )
        let store = StubProgressStore(recent: [movieProgress, tvProgress])

        let modelMovieKind = DiscoveryViewModel(
            discover: DiscoverMedia(repository: repo),
            getContinueWatching: GetContinueWatching(progressStore: store, mediaRepository: repo)
        )

        modelMovieKind.kind = .movie
        await modelMovieKind.reload()
        await modelMovieKind.loadContinueWatching()

        #expect(modelMovieKind.continueWatchingItems.contains(movieItem))
        #expect(!modelMovieKind.continueWatchingItems.contains(tvItem))

        let modelTVKind = DiscoveryViewModel(
            discover: DiscoverMedia(repository: repo),
            getContinueWatching: GetContinueWatching(progressStore: store, mediaRepository: repo)
        )

        modelTVKind.kind = .tv
        await modelTVKind.reload()
        await modelTVKind.loadContinueWatching()

        #expect(modelTVKind.continueWatchingItems.contains(tvItem))
        #expect(!modelTVKind.continueWatchingItems.contains(movieItem))
    }

    @Test func applyInitialPreferencesIfNeededSetsProfileIDAndKind() async {
        let repo = StubRepository(result: .success(ResultPage(items: [], page: 1, totalPages: 1)))

        struct ProfileSettingsRepositoryMock: ProfileRepository {
            func currentProfile() async throws -> ViewerProfile {
                ViewerProfile(id: "kids", name: "Kids", isMain: false)
            }

            func profiles() async throws -> [ViewerProfile] { [try await currentProfile()] }

            func preferences(for profileID: String) async throws -> UserPreferences {
                UserPreferences(defaultKind: .tv, autoplayTrailers: true)
            }

            func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {}

            func switchProfile(to profileID: String) async throws {}
        }

        let profileRepo = ProfileSettingsRepositoryMock()
        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: repo),
            getCurrentProfile: GetCurrentUserProfile(repository: profileRepo),
            getPreferences: GetUserPreferences(repository: profileRepo)
        )

        await model.applyInitialPreferencesIfNeeded()

        #expect(model.profileID == "kids")
        #expect(model.kind == .tv)
        #expect(model.filter.kind == .tv)
    }

    @Test func kindSwitchingSyncsFilterKind() {
        let model = DiscoveryViewModel(discover: DiscoverMedia(repository: StubRepository(result: .success(.empty))))
        #expect(model.kind == .movie)
        model.kind = .tv
        #expect(model.filter.kind == .tv)
    }

    @Test func featuredItemPrefersBackdropAndPresentedShelvesDeduplicate() async {
        let noBackdrop = MediaItem(id: MediaID(kind: .movie, value: 1), title: "No Backdrop")
        let hero = MediaItem(
            id: MediaID(kind: .movie, value: 2),
            title: "Hero Movie",
            backdropPath: "/hero.jpg"
        )
        let third = MediaItem(id: MediaID(kind: .movie, value: 3), title: "Third")
        let shelves = [
            MediaShelf(id: "popular", title: "Popular", items: [noBackdrop, hero, third]),
            MediaShelf(id: "rated", title: "Top Rated", items: [hero, noBackdrop]),
            MediaShelf(id: "duplicate-only", title: "Only Dups", items: [hero])
        ]

        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: StubRepository(result: .success(.empty))),
            getDiscoveryShelves: GetDiscoveryShelves(
                repository: MultiShelfStubRepository(pagesByFilter: shelves)
            )
        )

        #expect(model.featuredItem == nil)
        await model.reload()
        #expect(model.featuredItem == hero)
        #expect(model.presentedShelves.map(\.title) == ["Popular"])
        #expect(model.presentedShelves.first?.items == [noBackdrop, third])
    }

    @Test func loadNextPageAppendsItemsToPopularShelf() async {
        let first = MediaItem(id: MediaID(kind: .movie, value: 1), title: "First")
        let second = MediaItem(id: MediaID(kind: .movie, value: 2), title: "Second")
        let repo = PaginatedStubRepository(pages: [
            1: ResultPage(items: [first], page: 1, totalPages: 2),
            2: ResultPage(items: [second], page: 2, totalPages: 2)
        ])
        let model = DiscoveryViewModel(discover: DiscoverMedia(repository: repo))
        await model.reload()
        #expect(model.canLoadMore == true)

        await model.loadNextPage()
        if case .loaded(let shelves) = model.state {
            #expect(shelves.first?.items == [first, second])
        } else {
            Issue.record("Expected loaded state")
        }
        #expect(model.canLoadMore == false)
    }
}

private struct PaginatedStubRepository: MediaRepository {
    let pages: [Int: ResultPage<MediaItem>]
    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        pages[page] ?? .empty
    }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.notFound }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

private struct MultiShelfStubRepository: MediaRepository {
    let pagesByFilter: [MediaShelf]

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        let items: [MediaItem]
        switch filter.sort {
        case .popularity where filter.genreIDs.isEmpty:
            items = pagesByFilter.indices.contains(0) ? pagesByFilter[0].items : []
        case .rating:
            items = pagesByFilter.indices.contains(1) ? pagesByFilter[1].items : []
        case .newest:
            items = pagesByFilter.indices.contains(2) ? pagesByFilter[2].items : []
        default:
            items = []
        }
        return ResultPage(items: items, page: 1, totalPages: 1)
    }

    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.notFound }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
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

    @Test func preferredTrailerTitlePrefersTrailerNameAndFallsBack() async {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let detailsWithTrailer = MediaDetails(
            item: item,
            videos: [
                MediaVideo(id: "1", kind: .feature, name: "Featurette", site: "YouTube", key: "k1", language: "en"),
                MediaVideo(
                    id: "2",
                    kind: .trailer,
                    name: "Official Trailer",
                    site: "YouTube",
                    key: "k2",
                    language: "en"
                )
            ]
        )

        let detailsWithoutTrailer = MediaDetails(
            item: item,
            videos: [
                MediaVideo(id: "3", kind: .feature, name: "First Video", site: "YouTube", key: "k3", language: "en"),
                MediaVideo(id: "4", kind: .feature, name: "Second Video", site: "YouTube", key: "k4", language: "en")
            ]
        )

        let modelWithTrailer = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: DetailsRepository(details: detailsWithTrailer))
        )
        await modelWithTrailer.load()
        #expect(modelWithTrailer.preferredTrailerTitle == "Official Trailer")

        let modelWithoutTrailer = DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: DetailsRepository(details: detailsWithoutTrailer))
        )
        await modelWithoutTrailer.load()
        #expect(modelWithoutTrailer.preferredTrailerTitle == "First Video")
    }
}

private struct DetailsRepository: MediaRepository {
    let details: MediaDetails
    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { details }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}
