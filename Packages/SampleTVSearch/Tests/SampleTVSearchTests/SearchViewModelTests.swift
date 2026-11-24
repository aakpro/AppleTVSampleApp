import SampleTVDomain
import Testing
@testable import SampleTVSearch

private struct StubRepository: MediaRepository {
    var page: ResultPage<MediaItem> = .empty

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { self.page }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.unknown }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

@MainActor
struct SearchViewModelTests {
    private func item(_ value: Int, genres: [Int]) -> MediaItem {
        MediaItem(id: MediaID(kind: .tv, value: value), title: "T\(value)", genreIDs: genres)
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
}