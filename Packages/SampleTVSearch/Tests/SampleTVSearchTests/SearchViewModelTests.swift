import SampleTVDomain
import Testing
@testable import SampleTVSearch

private struct StubRepository: MediaRepository {
    var page: ResultPage<MediaItem> = .empty
    var genresResult: [Genre] = []

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { self.page }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.unknown }
    func genres(for kind: MediaKind) async throws -> [Genre] { genresResult }
}

@MainActor
struct SearchViewModelTests {
    private func item(_ value: Int, kind: MediaKind = .tv, genres: [Int]) -> MediaItem {
        MediaItem(id: MediaID(kind: kind, value: value), title: "T\(value)", genreIDs: genres)
    }

    @Test func shortTextStaysIdle() async {
        let model = SearchViewModel(search: SearchMedia(repository: StubRepository()), debounce: .milliseconds(1))
        model.text = "a"
        await model.performSearch()
        #expect(model.state == .idle)
    }

    @Test func resultsAreFilteredOnTheClient() async {
        let page = ResultPage(items: [item(1, genres: [18]), item(2, genres: [35])], page: 1, totalPages: 1)
        let model = SearchViewModel(
            search: SearchMedia(repository: StubRepository(page: page)), debounce: .milliseconds(1)
        )
        model.text = "show"
        model.filter = MediaFilter(kind: .tv, genreIDs: [35])
        await model.performSearch()
        #expect(model.state == .loaded([item(2, genres: [35])]))
    }

    @Test func allKindsFilterAllowsMixedMovieAndTVResultsByGenre() async {
        let movie = item(1, kind: .movie, genres: [28])
        let show = item(2, kind: .tv, genres: [35])
        let page = ResultPage(items: [movie, show], page: 1, totalPages: 1)
        let model = SearchViewModel(
            search: SearchMedia(repository: StubRepository(page: page)),
            debounce: .milliseconds(1)
        )
        model.selectedKind = nil
        model.filter.genreIDs = [28]
        model.text = "test"
        await model.performSearch()
        #expect(model.state == .loaded([movie]))
    }

    @Test func loadGenresPopulatesAvailableGenres() async {
        let repo = StubRepository(genresResult: [Genre(id: 28, name: "Action")])
        let model = SearchViewModel(
            search: SearchMedia(repository: repo),
            getGenres: GetGenres(repository: repo)
        )
        await model.loadGenres()
        #expect(model.availableGenres == [Genre(id: 28, name: "Action")])
    }

    @Test func retryRecoversFromFailedToLoaded() async {
        let expected = item(1, genres: [28])
        let repo = ToggleableSearchRepository(
            page: ResultPage(items: [expected], page: 1, totalPages: 1)
        )
        let model = SearchViewModel(
            search: SearchMedia(repository: repo),
            debounce: .milliseconds(1)
        )
        model.text = "heat"
        model.filter = MediaFilter(kind: .tv, genreIDs: [28])

        await model.performSearch()
        #expect(model.state == .failed(.offline))

        await repo.setShouldFail(false)
        await model.retry()
        #expect(model.state == .loaded([expected]))
    }
}

private actor ToggleableSearchRepository: MediaRepository {
    private var shouldFail = true
    private let page: ResultPage<MediaItem>

    init(page: ResultPage<MediaItem>) {
        self.page = page
    }

    func setShouldFail(_ value: Bool) {
        shouldFail = value
    }

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        if shouldFail {
            throw MediaError.offline
        }
        return self.page
    }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.unknown }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}
