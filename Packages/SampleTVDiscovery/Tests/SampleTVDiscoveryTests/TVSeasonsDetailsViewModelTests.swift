import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVDiscovery

private actor StubTVSeasonMediaRepository: MediaRepository {
    let detailsResult: MediaDetails
    private var seasonsByNumber: [Int: Result<TVSeasonDetails, MediaError>]
    private(set) var fetchedSeasonNumbers: [Int] = []

    init(
        detailsResult: MediaDetails,
        seasonsByNumber: [Int: Result<TVSeasonDetails, MediaError>] = [:]
    ) {
        self.detailsResult = detailsResult
        self.seasonsByNumber = seasonsByNumber
    }

    func setSeasonResult(_ result: Result<TVSeasonDetails, MediaError>, for seasonNumber: Int) {
        seasonsByNumber[seasonNumber] = result
    }

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { detailsResult }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }

    func seasonDetails(of id: MediaID, seasonNumber: Int) async throws -> TVSeasonDetails {
        fetchedSeasonNumbers.append(seasonNumber)
        guard let result = seasonsByNumber[seasonNumber] else {
            throw MediaError.notFound
        }
        return try result.get()
    }
}

private actor RecordingEpisodeResolver: PlaybackResourceResolver {
    private(set) var recordedEpisode: TVEpisode?
    let streamURL: URL

    init(streamURL: URL) {
        self.streamURL = streamURL
    }

    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        [PlayableResource(url: streamURL, kind: .feature, title: "Show", trackProgress: true)]
    }

    func resolve(_ mediaID: MediaID, genreIDs: [Int], episode: TVEpisode?) async throws -> [PlayableResource] {
        recordedEpisode = episode
        let subtitle = episode.map { "\($0.episodeCode) · \($0.name)" } ?? "Full Feature"
        return [
            PlayableResource(
                url: streamURL,
                kind: .feature,
                title: "Show",
                subtitle: subtitle,
                trackProgress: true
            )
        ]
    }
}

private struct StubTVProgressStore: PlaybackProgressStore {
    let records: [PlaybackProgress]

    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        records.first { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {}
    func clearProgress(for mediaID: MediaID, profileID: String) async throws {}
    func clearAllProgress(for profileID: String) async throws {}
    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] { records }
}

@MainActor
struct TVSeasonsDetailsViewModelTests {
    private let show = MediaItem(id: MediaID(kind: .tv, value: 1396), title: "Breaking Bad")

    private func makeSeason(number: Int, episodeNumbers: [Int]) -> TVSeasonDetails {
        let episodes = episodeNumbers.map { epNum in
            TVEpisode(
                id: (number * 100) + epNum,
                episodeNumber: epNum,
                seasonNumber: number,
                name: "Episode \(epNum)"
            )
        }
        return TVSeasonDetails(
            id: number,
            seasonNumber: number,
            name: number == 0 ? "Specials" : "Season \(number)",
            episodes: episodes
        )
    }

    @Test func loadAutoSelectsSeason1OverSpecialsAndLoadsEpisodes() async {
        let details = MediaDetails(
            item: show,
            seasons: [
                TVSeason(id: 0, seasonNumber: 0, name: "Specials", episodeCount: 2),
                TVSeason(id: 1, seasonNumber: 1, name: "Season 1", episodeCount: 2),
                TVSeason(id: 2, seasonNumber: 2, name: "Season 2", episodeCount: 3)
            ]
        )
        let repository = StubTVSeasonMediaRepository(
            detailsResult: details,
            seasonsByNumber: [
                1: .success(makeSeason(number: 1, episodeNumbers: [1, 2])),
                2: .success(makeSeason(number: 2, episodeNumbers: [1, 2, 3]))
            ]
        )

        let viewModel = DetailsViewModel(
            item: show,
            getDetails: GetMediaDetails(repository: repository),
            getSeasonDetails: GetTVSeasonDetails(repository: repository)
        )

        await viewModel.load()

        #expect(viewModel.selectedSeasonNumber == 1)
        #expect(viewModel.selectedSeasonEpisodes.map(\.episodeNumber) == [1, 2])
        #expect(viewModel.selectedEpisode?.episodeNumber == 1)
        #expect(viewModel.resumeLabel == "Play S1 E1")
    }

    @Test func resumableProgressAutoSelectsSavedSeasonAndEpisode() async {
        let details = MediaDetails(
            item: show,
            seasons: [
                TVSeason(id: 1, seasonNumber: 1, name: "Season 1", episodeCount: 2),
                TVSeason(id: 2, seasonNumber: 2, name: "Season 2", episodeCount: 3)
            ]
        )
        let repository = StubTVSeasonMediaRepository(
            detailsResult: details,
            seasonsByNumber: [
                1: .success(makeSeason(number: 1, episodeNumbers: [1, 2])),
                2: .success(makeSeason(number: 2, episodeNumbers: [1, 2, 3]))
            ]
        )
        let store = StubTVProgressStore(records: [
            PlaybackProgress(
                mediaID: show.id,
                position: 150,
                duration: 600,
                profileID: "main",
                seasonNumber: 2,
                episodeNumber: 3
            )
        ])

        let viewModel = DetailsViewModel(
            item: show,
            getDetails: GetMediaDetails(repository: repository),
            loadProgress: LoadPlaybackProgress(store: store),
            getSeasonDetails: GetTVSeasonDetails(repository: repository),
            profileID: "main"
        )

        await viewModel.load()

        #expect(viewModel.selectedSeasonNumber == 2)
        #expect(viewModel.selectedEpisode?.episodeNumber == 3)
        #expect(viewModel.isSelectedEpisodeResumable == true)
        #expect(viewModel.resumeLabel == "Resume S2 E3 · 02:30")

        await viewModel.selectSeason(1)
        #expect(viewModel.selectedSeasonNumber == 1)
        #expect(viewModel.selectedEpisode?.episodeNumber == 1)
        #expect(viewModel.isSelectedEpisodeResumable == false)
        #expect(viewModel.resumeLabel == "Play S1 E1")
    }

    @Test func selectSeasonCachesLoadedSeasonsAndSupportsRetryOnFailure() async {
        let details = MediaDetails(
            item: show,
            seasons: [
                TVSeason(id: 1, seasonNumber: 1, name: "Season 1", episodeCount: 1),
                TVSeason(id: 2, seasonNumber: 2, name: "Season 2", episodeCount: 1)
            ]
        )
        let repository = StubTVSeasonMediaRepository(
            detailsResult: details,
            seasonsByNumber: [
                1: .success(makeSeason(number: 1, episodeNumbers: [1])),
                2: .failure(.offline)
            ]
        )

        let viewModel = DetailsViewModel(
            item: show,
            getDetails: GetMediaDetails(repository: repository),
            getSeasonDetails: GetTVSeasonDetails(repository: repository)
        )

        await viewModel.load()
        await viewModel.selectSeason(2)
        #expect(viewModel.selectedSeasonState == .failed(.offline))
        #expect(viewModel.selectedEpisode == nil)

        await repository.setSeasonResult(.success(makeSeason(number: 2, episodeNumbers: [1, 2])), for: 2)
        await viewModel.retrySelectedSeason()
        #expect(viewModel.selectedSeasonEpisodes.map(\.episodeNumber) == [1, 2])
        #expect(viewModel.selectedEpisode?.episodeNumber == 1)

        await viewModel.selectSeason(1)
        #expect(viewModel.selectedEpisode?.episodeNumber == 1)
        #expect(await repository.fetchedSeasonNumbers == [1, 2, 2])
    }

    @Test func availableSeasonsSynthesizesFromSeasonCountWhenSeasonsEmpty() async {
        let details = MediaDetails(item: show, seasonCount: 3)
        let repository = StubTVSeasonMediaRepository(detailsResult: details)
        let viewModel = DetailsViewModel(
            item: show,
            getDetails: GetMediaDetails(repository: repository)
        )

        await viewModel.load()

        #expect(viewModel.availableSeasons.map(\.seasonNumber) == [1, 2, 3])
        #expect(viewModel.selectedSeasonNumber == 1)
    }

    @Test func selectEpisodeAndResolvePlayableResourceForwardEpisode() async throws {
        let url = try #require(URL(string: "https://example.com/ep.m3u8"))
        let details = MediaDetails(
            item: show,
            seasons: [TVSeason(id: 2, seasonNumber: 2, name: "Season 2", episodeCount: 5)]
        )
        let repository = StubTVSeasonMediaRepository(
            detailsResult: details,
            seasonsByNumber: [2: .success(makeSeason(number: 2, episodeNumbers: [1, 5]))]
        )
        let resolver = RecordingEpisodeResolver(streamURL: url)
        let viewModel = DetailsViewModel(
            item: show,
            getDetails: GetMediaDetails(repository: repository),
            resolveResources: ResolvePlaybackResources(resolver: resolver),
            getSeasonDetails: GetTVSeasonDetails(repository: repository)
        )

        await viewModel.load()
        let fifth = TVEpisode(id: 205, episodeNumber: 5, seasonNumber: 2, name: "Four Days Out")
        viewModel.selectEpisode(fifth)
        let resource = try await viewModel.resolvePlayableResource(kind: .feature, episode: fifth)

        #expect(viewModel.selectedEpisode == fifth)
        #expect(await resolver.recordedEpisode == fifth)
        #expect(resource?.subtitle == "S2 E5 · Four Days Out")
    }
}
