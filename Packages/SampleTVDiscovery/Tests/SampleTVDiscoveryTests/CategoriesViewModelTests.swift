import SampleTVDomain
import Testing
@testable import SampleTVDiscovery

@MainActor
struct CategoriesViewModelTests {
    @Test func loadPublishesMoviesAndTVShowsGenres() async {
        let repo = MockCategoryRepository(
            genresByKind: [
                .movie: [Genre(id: 28, name: "Action")],
                .tv: [Genre(id: 18, name: "Drama")]
            ]
        )
        let model = CategoriesViewModel(getGenres: GetGenres(repository: repo))

        await model.load()

        #expect(model.state == .loaded(
            movies: [Genre(id: 28, name: "Action")],
            tvShows: [Genre(id: 18, name: "Drama")]
        ))
    }

    @Test func loadSetsFailedStateOnError() async {
        let repo = MockCategoryRepository(error: .offline)
        let model = CategoriesViewModel(getGenres: GetGenres(repository: repo))

        await model.load()

        #expect(model.state == .failed(.offline))
    }
}

private struct MockCategoryRepository: MediaRepository {
    var genresByKind: [MediaKind: [Genre]] = [:]
    var error: MediaError?

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.notFound }
    func genres(for kind: MediaKind) async throws -> [Genre] {
        if let error { throw error }
        return genresByKind[kind] ?? []
    }
}
