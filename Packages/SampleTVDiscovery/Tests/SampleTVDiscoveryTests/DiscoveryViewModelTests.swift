import Testing
import SampleTVDomain
@testable import SampleTVDiscovery

private struct StubRepository: MediaRepository {
    var result: Result<ResultPage<MediaItem>, MediaError>

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.unknown }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
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