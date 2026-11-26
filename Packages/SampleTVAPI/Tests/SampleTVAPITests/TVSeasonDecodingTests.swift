import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVAPI

struct TVSeasonDecodingTests {
    @Test func tvDetailsDecodesSeasonsAndFiltersOutEmptySpecials() async throws {
        let body = """
        {
            "id": 1396,
            "name": "Breaking Bad",
            "seasons": [
                {"id": 3577, "season_number": 0, "episode_count": 0, "name": "Specials"},
                {"id": 3572, "season_number": 1, "episode_count": 7, "name": "Season 1"},
                {"id": 3573, "season_number": 2, "episode_count": 13, "name": "Season 2"}
            ]
        }
        """

        let stub = StubTransport([StubResponse(body: body)])
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: "token"),
            transport: stub,
            retryPolicy: RetryPolicy(maxAttempts: 1, baseDelay: .milliseconds(1))
        )
        let repository = TMDBMediaRepository(client: client)

        let details = try await repository.details(of: MediaID(kind: .tv, value: 1396))

        #expect(details.seasons.map(\.seasonNumber) == [1, 2])
        #expect(details.seasons.first?.episodeCount == 7)
    }

    @Test func tvDetailsOrdersRegularSeasonsBeforeNonEmptySpecialsAndFillsFallbackNames() async throws {
        let body = """
        {
            "id": 1396,
            "name": "Breaking Bad",
            "seasons": [
                {"id": 3577, "season_number": 0, "episode_count": 4, "name": ""},
                {"id": 3573, "season_number": 2, "episode_count": 13, "name": ""},
                {"id": 3572, "season_number": 1, "episode_count": 7, "name": "First Season"}
            ]
        }
        """

        let stub = StubTransport([StubResponse(body: body)])
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: "token"),
            transport: stub,
            retryPolicy: RetryPolicy(maxAttempts: 1, baseDelay: .milliseconds(1))
        )
        let repository = TMDBMediaRepository(client: client)

        let details = try await repository.details(of: MediaID(kind: .tv, value: 1396))

        #expect(details.seasons.map(\.seasonNumber) == [1, 2, 0])
        #expect(details.seasons.map(\.name) == ["First Season", "Season 2", "Specials"])
    }

    @Test func seasonDetailsSortsEpisodesMapsZeroRatingAndBlankNames() async throws {
        let body = """
        {
            "id": 3573,
            "season_number": 2,
            "name": "",
            "episodes": [
                {"id": 103, "episode_number": 3, "name": "", "vote_average": 0},
                {"id": 101, "episode_number": 1, "name": "Seven Thirty-Seven", "runtime": 47, "vote_average": 8.4},
                {"id": 102, "episode_number": 2, "name": "Grilled", "still_path": "/still.jpg", "vote_average": 9.1}
            ]
        }
        """

        let stub = StubTransport([StubResponse(body: body)])
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: "token"),
            transport: stub,
            retryPolicy: RetryPolicy(maxAttempts: 1, baseDelay: .milliseconds(1))
        )
        let repository = TMDBMediaRepository(client: client)

        let seasonDetails = try await repository.seasonDetails(
            of: MediaID(kind: .tv, value: 1396),
            seasonNumber: 2
        )

        let request = try #require(await stub.requests.first)
        #expect(request.url?.path.hasSuffix("/tv/1396/season/2") == true)
        #expect(seasonDetails.name == "Season 2")
        #expect(seasonDetails.episodes.map(\.episodeNumber) == [1, 2, 3])
        #expect(seasonDetails.episodes[0].runtimeMinutes == 47)
        #expect(seasonDetails.episodes[1].stillPath == "/still.jpg")
        #expect(seasonDetails.episodes[2].name == "Episode 3")
        #expect(seasonDetails.episodes[2].rating == nil)
    }

    @Test func seasonDetailsRejectsMovieOrNegativeSeasonWithoutRequests() async throws {
        let stub = StubTransport([])
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: "token"),
            transport: stub,
            retryPolicy: RetryPolicy(maxAttempts: 1, baseDelay: .milliseconds(1))
        )
        let repository = TMDBMediaRepository(client: client)

        await #expect(throws: MediaError.notFound) {
            _ = try await repository.seasonDetails(of: MediaID(kind: .movie, value: 603), seasonNumber: 1)
        }
        await #expect(throws: MediaError.notFound) {
            _ = try await repository.seasonDetails(of: MediaID(kind: .tv, value: 1396), seasonNumber: -1)
        }
        #expect(await stub.requests.isEmpty)
    }

    @Test func catalogPlaybackResourceResolverSetsEpisodeSubtitle() async throws {
        let episode = TVEpisode(
            id: 62_085,
            episodeNumber: 5,
            seasonNumber: 2,
            name: "Four Days Out"
        )
        let resolver = CatalogPlaybackResourceResolver()

        let resources = try await resolver.resolve(
            MediaID(kind: .tv, value: 1396),
            genreIDs: [18],
            episode: episode
        )

        #expect(resources.first?.subtitle == "S2 E5 · Four Days Out")
    }
}
