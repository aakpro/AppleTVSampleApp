/// Composition root. Phases 2-6 add the repository and one factory method per feature.
import Foundation
import SampleTVAPI
import SampleTVDiscovery
import SampleTVDomain
import SampleTVPlaybackProgress
import SampleTVSearch

@MainActor
final class AppContainer {
    /// Public Apple test stream. TMDB provides metadata only, never video.
    static let sampleStream = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    )!

    let configuration: AppConfiguration
    let repository: any MediaRepository
    let progressStore: any PlaybackProgressStore

    init(configuration: AppConfiguration, repository: any MediaRepository, progressStore: any PlaybackProgressStore) {
        self.configuration = configuration
        self.repository = repository
        self.progressStore = progressStore
    }

    static func live() -> AppContainer {
        let configuration = AppConfiguration()
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: configuration.tmdbToken),
            transport: URLSession.tmdbCached()
        )
        let progressStore = UserDefaultsPlaybackProgressStore()
        return AppContainer(
            configuration: configuration, 
            repository: TMDBMediaRepository(client: client),
            progressStore: progressStore
        )
    }

    func makeDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(discover: DiscoverMedia(repository: repository), progressStore: progressStore)
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(search: SearchMedia(repository: repository))
    }

    func makeDetailsViewModel(for item: MediaItem) -> DetailsViewModel {
        DetailsViewModel(item: item, getDetails: GetMediaDetails(repository: repository))
    }

    /// Seam for a real catalogue: map a title to its stream. Always the sample stream for now.
    func playbackURL(for item: MediaItem) -> URL {
        Self.sampleStream
    }
}
