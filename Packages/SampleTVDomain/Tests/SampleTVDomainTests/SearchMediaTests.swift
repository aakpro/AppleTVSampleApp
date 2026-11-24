import Testing
@testable import SampleTVDomain

private final class SpyRepository: MediaRepository, @unchecked Sendable {
    private(set) var searchCalls = 0
    private(set) var discoverCalls = 0
    private(set) var lastFilter: MediaFilter?
    private(set) var lastPage: Int?

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        discoverCalls += 1
        lastFilter = filter
        lastPage = page
        return .empty
    }

    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        searchCalls += 1
        return .empty
    }

    func details(of id: MediaID) async throws -> MediaDetails {
        MediaDetails(item: MediaItem(id: id, title: "x"))
    }

    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

struct SearchMediaTests {
    @Test func shortTextNeverReachesRepository() async throws {
        let repository = SpyRepository()
        let page = try await SearchMedia(repository: repository)(" a ")
        #expect(page == .empty)
        #expect(repository.searchCalls == 0)
    }

    @Test func validTextIsTrimmedAndForwarded() async throws {
        let repository = SpyRepository()
        _ = try await SearchMedia(repository: repository)("  dark  ")
        #expect(repository.searchCalls == 1)
        #expect(SearchQuery("  dark  ")?.text == "dark")
    }

    @Test func emptyStringRejectsByInit() {
        let query = SearchQuery("")
        #expect(query == nil)
    }

    @Test func whitespaceOnlyStringRejectsByInit() {
        let query = SearchQuery("   ")
        #expect(query == nil)
    }

    @Test func textWithKindIsFiltered() async throws {
        let repository = SpyRepository()
        _ = try await SearchMedia(repository: repository)("test", kind: .movie, page: 3)
        #expect(repository.searchCalls == 1)
    }

    @Test func invalidPageClampsToMin() async throws {
        let repository = SpyRepository()
        _ = try await SearchMedia(repository: repository)("dark", kind: .tv, page: -5)
        #expect(repository.searchCalls == 1)
    }

    @Test func emptyTextMakesEmptyResultImmediately() async throws {
        let repository = SpyRepository()
        _ = try await SearchMedia(repository: repository)(" ")
        #expect(repository.searchCalls == 0)
    }

    @Test func discoverPageIsClampedToMinimumOne() async throws {
        let repository = SpyRepository()
        _ = try await DiscoverMedia(repository: repository)(MediaFilter(kind: .movie), page: -10)
        #expect(repository.discoverCalls == 1)
        #expect(repository.lastPage == 1)
    }

    @Test func resultPageHasNextPageWorks() {
        let pageWithMore = ResultPage(items: [1], page: 1, totalPages: 5)
        #expect(pageWithMore.hasNextPage)

        let lastPage = ResultPage(items: [1], page: 5, totalPages: 5)
        #expect(!lastPage.hasNextPage)
    }

    @Test func getMediaDetailsDelegatesToRepository() async throws {
        let repository = SpyRepository()
        let details = try await GetMediaDetails(repository: repository)(MediaID(kind: .movie, value: 42))
        #expect(details.item.id == MediaID(kind: .movie, value: 42))
    }
}
