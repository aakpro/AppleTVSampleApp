/// Composition root. Phases 2-6 add the repository and one factory method per feature.
import Foundation
import SampleTVAPI
import SampleTVDiscovery
import SampleTVDomain

@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    let repository: any MediaRepository

    init(configuration: AppConfiguration, repository: any MediaRepository) {
        self.configuration = configuration
        self.repository = repository
    }

    static func live() -> AppContainer {
        let configuration = AppConfiguration()
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: configuration.tmdbToken),
            transport: URLSession.tmdbCached()
        )
        return AppContainer(configuration: configuration, repository: TMDBMediaRepository(client: client))
    }

    func makeDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(discover: DiscoverMedia(repository: repository))
    }

    func makeDetailsViewModel(for item: MediaItem) -> DetailsViewModel {
        DetailsViewModel(item: item, getDetails: GetMediaDetails(repository: repository))
    }
}
