/// Composition root. Phases 2-6 add the repository and one factory method per feature.
import Foundation
import SampleTVAPI
import SampleTVAuth
import SampleTVDiscovery
import SampleTVDomain
import SampleTVPersistence
import SampleTVProfile
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
    let authRepository: any AuthRepository
    let profileRepository: any ProfileRepository
    let resourceResolver: any PlaybackResourceResolver
    let watchlistStore: any WatchlistStore

    init(
        configuration: AppConfiguration,
        repository: any MediaRepository,
        progressStore: any PlaybackProgressStore,
        authRepository: any AuthRepository,
        profileRepository: any ProfileRepository,
        resourceResolver: any PlaybackResourceResolver,
        watchlistStore: any WatchlistStore
    ) {
        self.configuration = configuration
        self.repository = repository
        self.progressStore = progressStore
        self.authRepository = authRepository
        self.profileRepository = profileRepository
        self.resourceResolver = resourceResolver
        self.watchlistStore = watchlistStore
    }

    static func live() -> AppContainer {
        let configuration = AppConfiguration()
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: configuration.tmdbToken),
            transport: URLSession.tmdbCached()
        )
        let sessionStore = KeychainSessionStore()
        if ProcessInfo.processInfo.arguments.contains("-reset-auth") {
            sessionStore.clear()
        }
        let authRepository = MockAuthRepository(sessionStore: sessionStore)
        let modelContainer = PersistenceContainer.makeResilientModelContainer()
        let profileRepository = SwiftDataProfileRepository(modelContainer: modelContainer)
        let resourceResolver = CatalogPlaybackResourceResolver()
        let watchlistStore = SwiftDataWatchlistStore(modelContainer: modelContainer)
        let playbackProgressStore = SwiftDataPlaybackProgressStore(modelContainer: modelContainer)

        return AppContainer(
            configuration: configuration,
            repository: TMDBMediaRepository(client: client),
            progressStore: playbackProgressStore,
            authRepository: authRepository,
            profileRepository: profileRepository,
            resourceResolver: resourceResolver,
            watchlistStore: watchlistStore
        )
    }

    func makeDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(
            discover: DiscoverMedia(repository: repository),
            getDiscoveryShelves: GetDiscoveryShelves(repository: repository),
            getDetails: GetMediaDetails(repository: repository),
            progressStore: progressStore
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            search: SearchMedia(repository: repository),
            getGenres: GetGenres(repository: repository)
        )
    }

    func makeDetailsViewModel(for item: MediaItem, profileID: String = ViewerProfile.defaultID) -> DetailsViewModel {
        DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            progressStore: progressStore,
            resourceResolver: resourceResolver,
            watchlistStore: watchlistStore,
            profileID: profileID
        )
    }

    /// Seam for a real catalogue: map a title to its stream. Always the sample stream for now.
    func playbackURL(for item: MediaItem) -> URL {
        Self.sampleStream
    }

    func makeLoginViewModel(onAuthenticated: @MainActor @Sendable @escaping (UserAccount) -> Void) -> LoginViewModel {
        LoginViewModel(
            signIn: SignIn(repository: authRepository),
            signInDemo: SignInDemo(repository: authRepository),
            onAuthenticated: onAuthenticated
        )
    }

    func makeProfileViewModel(onSignOut: @MainActor @Sendable @escaping () -> Void) -> ProfileViewModel {
        ProfileViewModel(
            getCurrentProfile: GetCurrentUserProfile(repository: profileRepository),
            getProfiles: GetProfiles(repository: profileRepository),
            getPreferences: GetUserPreferences(repository: profileRepository),
            updatePreferences: UpdateUserPreferences(repository: profileRepository),
            switchProfile: SwitchProfile(repository: profileRepository),
            signOut: SignOut(repository: authRepository),
            progressStore: progressStore,
            watchlistStore: watchlistStore,
            onSignOut: onSignOut
        )
    }
}
