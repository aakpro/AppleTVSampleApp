import SampleTVDomain
import SampleTVUI
import Testing
@testable import SampleTVDiscovery

@MainActor
struct CategoryResultsViewModelTests {
    @Test func reloadPopulatesInitialPageAndLoadNextPageAppends() async {
        let item1 = MediaItem(id: MediaID(kind: .movie, value: 1), title: "Movie 1")
        let item2 = MediaItem(id: MediaID(kind: .movie, value: 2), title: "Movie 2")
        let repo = StubResultsRepository(pagesByNumber: [
            1: ResultPage(items: [item1], page: 1, totalPages: 2),
            2: ResultPage(items: [item2], page: 2, totalPages: 2)
        ])

        let model = CategoryResultsViewModel(
            discover: DiscoverMedia(repository: repo),
            kind: .movie,
            genre: Genre(id: 28, name: "Action")
        )

        await model.reload()
        #expect(model.state == .loaded([item1]))
        #expect(model.canLoadMore == true)

        await model.loadNextPage()
        #expect(model.items == [item1, item2])
        #expect(model.canLoadMore == false)
    }

    @Test func reloadSetsFailedStateOnError() async {
        let repo = StubResultsRepository(error: .offline)
        let model = CategoryResultsViewModel(
            discover: DiscoverMedia(repository: repo),
            kind: .tv
        )

        await model.reload()

        #expect(model.state == .failed(.offline))
        #expect(model.error == .offline)
    }

    @Test func sortUpdatePassesUpdatedFilterToRepository() async {
        let spy = SpyResultsRepository()
        let model = CategoryResultsViewModel(
            discover: DiscoverMedia(repository: spy),
            kind: .movie
        )

        model.sort = .rating
        await model.reload()

        let recorded = await spy.recordedFilters
        #expect(recorded.last?.sort == .rating)
    }
}

private struct StubResultsRepository: MediaRepository {
    var pagesByNumber: [Int: ResultPage<MediaItem>] = [:]
    var error: MediaError?

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        if let error { throw error }
        return pagesByNumber[page] ?? .empty
    }

    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.notFound }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

private actor SpyResultsRepository: MediaRepository {
    private(set) var recordedFilters: [MediaFilter] = []

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        recordedFilters.append(filter)
        return .empty
    }

    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.notFound }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}
