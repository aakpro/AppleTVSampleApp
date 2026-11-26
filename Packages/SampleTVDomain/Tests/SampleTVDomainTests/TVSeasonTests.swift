import Foundation
import Testing
@testable import SampleTVDomain

@Suite struct TVSeasonTests {
    @Test func episodeCodeFormatsCorrectly() {
        let episode = TVEpisode(
            id: 42,
            episodeNumber: 5,
            seasonNumber: 2,
            name: "Four Days Out",
            overview: "Walt and Jesse cook in the desert.",
            stillPath: "/path.jpg",
            rating: 8.6
        )

        #expect(episode.episodeCode == "S2 E5")
    }

    @Test func getTVSeasonDetailsSucceedsForTV() async throws {
        let repository = StubTVSeasonRepository(
            seasonsByNumber: [
                1: TVSeasonDetails(id: 101, seasonNumber: 1, name: "Season 1", episodes: [])
            ]
        )

        let useCase = GetTVSeasonDetails(repository: repository)
        let result = try await useCase(of: MediaID(kind: .tv, value: 1396), seasonNumber: 1)

        #expect(result.seasonNumber == 1)
        #expect(result.name == "Season 1")
    }

    @Test func getTVSeasonDetailsRejectsMovieWithNotFound() async {
        let repository = StubTVSeasonRepository(
            seasonsByNumber: [
                1: TVSeasonDetails(id: 101, seasonNumber: 1, name: "Season 1")
            ]
        )

        let useCase = GetTVSeasonDetails(repository: repository)
        await #expect(throws: MediaError.notFound) {
            _ = try await useCase(of: MediaID(kind: .movie, value: 1396), seasonNumber: 1)
        }
    }

    @Test func getTVSeasonDetailsRejectsNegativeSeasonWithNotFound() async {
        let repository = StubTVSeasonRepository(seasonsByNumber: [:])
        let useCase = GetTVSeasonDetails(repository: repository)

        await #expect(throws: MediaError.notFound) {
            _ = try await useCase(of: MediaID(kind: .tv, value: 1396), seasonNumber: -1)
        }
    }

    @Test func resolvePlaybackResourcesPassesEpisodeToCustomResolver() async throws {
        let episode = TVEpisode(
            id: 62_085,
            episodeNumber: 5,
            seasonNumber: 2,
            name: "Four Days Out"
        )
        let customResolver = RecordingPlaybackResourceResolver()
        let useCase = ResolvePlaybackResources(resolver: customResolver)

        let resources = try await useCase(
            MediaID(kind: .tv, value: 1396),
            genreIDs: [18],
            episode: episode
        )

        #expect(resources.count == 1)
        #expect(await customResolver.recordedEpisode == episode)
    }

    @Test func resolvePlaybackResourcesFallsBackToLegacyResolver() async throws {
        let legacyResolver = LegacyPlaybackResourceResolver()
        let useCase = ResolvePlaybackResources(resolver: legacyResolver)
        let episode = TVEpisode(id: 1, episodeNumber: 1, seasonNumber: 1, name: "Pilot")

        let resources = try await useCase(
            MediaID(kind: .tv, value: 1396),
            genreIDs: [18],
            episode: episode
        )

        #expect(resources.count == 1)
        #expect(await legacyResolver.callCount == 1)
    }

    @Test func playbackProgressDecodesLegacyJSONWithoutSeasonAndEpisodeNumbersAsNil() throws {
        let legacyJSON = """
        {
            "mediaID": {"kind": "tv", "value": 1396},
            "position": 100,
            "duration": 600,
            "updatedAt": 0,
            "profileID": "main"
        }
        """

        let data = try #require(legacyJSON.data(using: .utf8))
        let progress = try JSONDecoder().decode(PlaybackProgress.self, from: data)

        #expect(progress.seasonNumber == nil)
        #expect(progress.episodeNumber == nil)
    }

    @Test func playbackProgressRoundTripsSeasonAndEpisodeNumbersWhenPresent() throws {
        let progress = PlaybackProgress(
            mediaID: MediaID(kind: .tv, value: 1396),
            position: 100,
            duration: 600,
            updatedAt: Date(timeIntervalSince1970: 1_000),
            profileID: "main",
            seasonNumber: 2,
            episodeNumber: 5
        )

        let encoded = try JSONEncoder().encode(progress)
        let decoded = try JSONDecoder().decode(PlaybackProgress.self, from: encoded)

        #expect(decoded.seasonNumber == 2)
        #expect(decoded.episodeNumber == 5)
    }
}

private struct StubTVSeasonRepository: MediaRepository {
    let seasonsByNumber: [Int: TVSeasonDetails]

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { MediaDetails(item: MediaItem(id: id, title: "Show")) }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }

    func seasonDetails(of id: MediaID, seasonNumber: Int) async throws -> TVSeasonDetails {
        guard let details = seasonsByNumber[seasonNumber] else {
            throw MediaError.notFound
        }
        return details
    }
}

private actor RecordingPlaybackResourceResolver: PlaybackResourceResolver {
    private(set) var recordedEpisode: TVEpisode?

    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        []
    }

    func resolve(_ mediaID: MediaID, genreIDs: [Int], episode: TVEpisode?) async throws -> [PlayableResource] {
        recordedEpisode = episode
        let url = try #require(URL(string: "https://example.com/episode.m3u8"))
        return [PlayableResource(url: url, kind: .feature, title: "Show", trackProgress: true)]
    }
}

private actor LegacyPlaybackResourceResolver: PlaybackResourceResolver {
    private(set) var callCount = 0

    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        callCount += 1
        let url = try #require(URL(string: "https://example.com/legacy.m3u8"))
        return [PlayableResource(url: url, kind: .feature, title: "Show", trackProgress: true)]
    }
}
