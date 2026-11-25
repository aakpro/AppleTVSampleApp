import Foundation
import Testing
@testable import SampleTVDomain

@Suite struct CategoriesTests {
    @Test func mediaShelfStoresIDTitleAndItems() {
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 1),
            title: "Test Movie"
        )
        let shelf = MediaShelf(id: "popular", title: "Popular", items: [item])

        #expect(shelf.id == "popular")
        #expect(shelf.title == "Popular")
        #expect(shelf.items == [item])
    }

    @Test func getGenresReturnsGenresFromRepository() async throws {
        let mockRepo = StubMediaRepository(
            genresResult: [Genre(id: 28, name: "Action"), Genre(id: 35, name: "Comedy")]
        )
        let getGenres = GetGenres(repository: mockRepo)

        let genres = try await getGenres(for: .movie)
        #expect(genres.count == 2)
        #expect(genres.map(\.name) == ["Action", "Comedy"])
    }

    @Test func getDiscoveryShelvesLoadsCuratedAndGenreShelves() async throws {
        let movie = MediaItem(id: MediaID(kind: .movie, value: 10), title: "Inception")
        let mockRepo = StubMediaRepository(
            genresResult: [Genre(id: 28, name: "Action"), Genre(id: 35, name: "Comedy")],
            discoverHandler: { _, _ in
                ResultPage(items: [movie], page: 1, totalPages: 1)
            }
        )
        let getShelves = GetDiscoveryShelves(repository: mockRepo)

        let shelves = try await getShelves(for: .movie)
        let titles = shelves.map(\.title)
        #expect(titles == ["Popular", "Top Rated", "New Releases", "Action", "Comedy"])
        #expect(shelves.allSatisfy { $0.items == [movie] })
    }

    @Test func getDiscoveryShelvesIsolatesIndividualShelfFailures() async throws {
        struct StubFailure: Error {}
        let movie = MediaItem(id: MediaID(kind: .movie, value: 10), title: "Inception")
        let mockRepo = StubMediaRepository(
            genresResult: [Genre(id: 28, name: "Action")],
            discoverHandler: { filter, _ in
                if filter.sort == .rating {
                    throw StubFailure()
                }
                return ResultPage(items: [movie], page: 1, totalPages: 1)
            }
        )
        let getShelves = GetDiscoveryShelves(repository: mockRepo)

        let shelves = try await getShelves(for: .movie)
        let titles = shelves.map(\.title)
        #expect(titles == ["Popular", "New Releases", "Action"])
    }
}

private struct StubMediaRepository: MediaRepository {
    var genresResult: [Genre] = []
    var discoverHandler: @Sendable (MediaFilter, Int) async throws -> ResultPage<MediaItem> = { _, _ in .empty }

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        try await discoverHandler(filter, page)
    }

    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        .empty
    }

    func details(of id: MediaID) async throws -> MediaDetails {
        MediaDetails(item: MediaItem(id: id, title: "Test"))
    }

    func genres(for kind: MediaKind) async throws -> [Genre] {
        genresResult
    }
}
