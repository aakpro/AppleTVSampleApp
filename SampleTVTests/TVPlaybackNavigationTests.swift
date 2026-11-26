import Foundation
import SampleTVDomain
import Testing
@testable import SampleTV

@MainActor
struct TVPlaybackNavigationTests {
    @Test func startPlaybackForEpisodeForwardsEpisodeAndSetsSubtitle() async throws {
        let item = MediaItem(id: MediaID(kind: .tv, value: 1396), title: "Breaking Bad", genreIDs: [18])
        let resolvedURL = try #require(URL(string: "https://example.com/ep.m3u8"))
        let fallbackURL = try #require(URL(string: "https://example.com/fallback.m3u8"))
        let episode = TVEpisode(id: 205, episodeNumber: 5, seasonNumber: 2, name: "Four Days Out")
        let resolver = RecordingNavigationEpisodeResolver(streamURL: resolvedURL)

        let viewModel = DetailsScreenViewModel(
            resolveResources: ResolvePlaybackResources(resolver: resolver),
            fallbackURL: { _ in fallbackURL },
            profileID: "kids"
        )

        await viewModel.startPlayback(for: item, episode: episode, kind: .feature)

        #expect(await resolver.recordedEpisode == episode)
        #expect(viewModel.playbackSelection?.episode == episode)
        #expect(viewModel.playbackSelection?.resource.title == "Breaking Bad")
        #expect(viewModel.playbackSelection?.resource.subtitle == "S2 E5 · Four Days Out")
    }

    @Test func saveProgressStoresSeasonAndEpisodeNumbers() async throws {
        let url = try #require(URL(string: "https://example.com/stream.m3u8"))
        let store = InMemoryEpisodeProgressStore()
        let episode = TVEpisode(id: 205, episodeNumber: 5, seasonNumber: 2, name: "Four Days Out")
        let selection = PlaybackSelection(
            mediaID: MediaID(kind: .tv, value: 1396),
            profileID: "kids",
            resource: PlayableResource(url: url, kind: .feature, title: "Breaking Bad", trackProgress: true),
            episode: episode
        )

        let viewModel = PlayerScreenViewModel(
            selection: selection,
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await viewModel.saveProgress(position: 90, duration: 600)

        let saved = try await store.loadProgress(for: MediaID(kind: .tv, value: 1396), profileID: "kids")
        #expect(saved?.seasonNumber == 2)
        #expect(saved?.episodeNumber == 5)
    }

    @Test func loadRestoresInitialPositionOnlyWhenSeasonAndEpisodeMatch() async throws {
        let url = try #require(URL(string: "https://example.com/stream.m3u8"))
        let store = InMemoryEpisodeProgressStore(records: [
            PlaybackProgress(
                mediaID: MediaID(kind: .tv, value: 1396),
                position: 120,
                duration: 600,
                profileID: "kids",
                seasonNumber: 2,
                episodeNumber: 5
            )
        ])

        let matchingSelection = PlaybackSelection(
            mediaID: MediaID(kind: .tv, value: 1396),
            profileID: "kids",
            resource: PlayableResource(url: url, kind: .feature, title: "Breaking Bad", trackProgress: true),
            episode: TVEpisode(id: 205, episodeNumber: 5, seasonNumber: 2, name: "Four Days Out")
        )
        let matchingVM = PlayerScreenViewModel(
            selection: matchingSelection,
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await matchingVM.load()
        #expect(matchingVM.initialPosition == 120)

        let otherSelection = PlaybackSelection(
            mediaID: MediaID(kind: .tv, value: 1396),
            profileID: "kids",
            resource: PlayableResource(url: url, kind: .feature, title: "Breaking Bad", trackProgress: true),
            episode: TVEpisode(id: 204, episodeNumber: 4, seasonNumber: 2, name: "Down")
        )
        let otherVM = PlayerScreenViewModel(
            selection: otherSelection,
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await otherVM.load()
        #expect(otherVM.initialPosition == nil)
    }
}

private actor RecordingNavigationEpisodeResolver: PlaybackResourceResolver {
    let streamURL: URL
    private(set) var recordedEpisode: TVEpisode?

    init(streamURL: URL) {
        self.streamURL = streamURL
    }

    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        [PlayableResource(url: streamURL, kind: .feature, title: "Show", trackProgress: true)]
    }

    func resolve(_ mediaID: MediaID, genreIDs: [Int], episode: TVEpisode?) async throws -> [PlayableResource] {
        recordedEpisode = episode
        return [PlayableResource(url: streamURL, kind: .feature, title: "Show", trackProgress: true)]
    }
}

private actor InMemoryEpisodeProgressStore: PlaybackProgressStore {
    private var records: [PlaybackProgress]

    init(records: [PlaybackProgress] = []) {
        self.records = records
    }

    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        records.first { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {
        records.removeAll { $0.mediaID == progress.mediaID && $0.profileID == progress.profileID }
        records.insert(progress, at: 0)
    }

    func clearProgress(for mediaID: MediaID, profileID: String) async throws {
        records.removeAll { $0.mediaID == mediaID && $0.profileID == profileID }
    }

    func clearAllProgress(for profileID: String) async throws {
        records.removeAll { $0.profileID == profileID }
    }

    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] {
        Array(records.filter { $0.profileID == profileID }.prefix(maxCount))
    }
}
