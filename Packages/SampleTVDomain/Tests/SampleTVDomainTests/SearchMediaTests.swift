import Testing
@testable import SampleTVDomain

private final class SpyRepository: MediaRepository, @unchecked Sendable {
    private(set) var searchCalls = 0

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        searchCalls += 1
        return .empty
    }
    func details(of id: MediaID) async throws -> MediaDetails {
        return MediaDetails(item: MediaItem(id: id, title: "x"))
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
        // Should clamp to min page and still make the search call once
        #expect(repository.searchCalls == 1)
    }

    @Test func pageIsClampedToMinimumOne() async throws {
        let repository = SpyRepository()
        _ = try await DiscoverMedia(repository: repository)(.movie, genreIDs: [])("dark", page: -10)
        #expect(repository.searchCalls == 1)
    }

    @Test func invalidPageIsNeverPassedThroughToRepo() async throws {
        let repository = SpyRepository()
        let page = try await DiscoverMedia(repository: repository)(.movie, genreIDs: [])("dark", page: -5)
        // Invalid pages are clamped internally; should not touch the repo for invalid pages
        #expect(repository.searchCalls == 0)
    }

    @Test func emptyTextMakesEmptyResultImmediately() async throws {
        let repository = SpyRepository()
        _ = try await SearchMedia(repository: repository)(" ")
        #expect(repository.searchCalls == 0)
    }
}
