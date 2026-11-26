import Foundation
import SampleTVAuth
import SampleTVDiscovery
import SampleTVDomain
import SampleTVProfile
import SampleTVSearch

@MainActor
extension AppContainer {
    func makeRootViewModel() -> RootViewModel {
        RootViewModel(
            loadCurrentAccount: LoadCurrentAccount(repository: authRepository),
            getCurrentProfile: GetCurrentUserProfile(repository: profileRepository),
            hasTMDBToken: configuration.hasToken
        )
    }

    func makeDiscoveryViewModel(profileID: String = ViewerProfile.defaultID) -> DiscoveryViewModel {
        DiscoveryViewModel(
            discover: DiscoverMedia(repository: repository),
            getDiscoveryShelves: GetDiscoveryShelves(repository: repository),
            getContinueWatching: GetContinueWatching(
                progressStore: progressStore,
                mediaRepository: repository
            ),
            profileID: profileID,
            getCurrentProfile: GetCurrentUserProfile(repository: profileRepository),
            getPreferences: GetUserPreferences(repository: profileRepository)
        )
    }

    func makeCategoriesViewModel() -> CategoriesViewModel {
        CategoriesViewModel(getGenres: GetGenres(repository: repository))
    }

    func makeCategoryResultsViewModel(kind: MediaKind, genre: Genre?) -> CategoryResultsViewModel {
        CategoryResultsViewModel(
            discover: DiscoverMedia(repository: repository),
            kind: kind,
            genre: genre
        )
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            search: SearchMedia(repository: repository),
            getGenres: GetGenres(repository: repository)
        )
    }

    func makeDetailsViewModel(
        for item: MediaItem,
        profileID: String = ViewerProfile.defaultID
    ) -> DetailsViewModel {
        DetailsViewModel(
            item: item,
            getDetails: GetMediaDetails(repository: repository),
            loadProgress: LoadPlaybackProgress(store: progressStore),
            resolveResources: ResolvePlaybackResources(resolver: resourceResolver),
            isInWatchlist: IsInWatchlist(store: watchlistStore),
            toggleWatchlist: ToggleWatchlist(store: watchlistStore),
            profileID: profileID
        )
    }

    func makeDetailsScreenViewModel(profileID: String = ViewerProfile.defaultID) -> DetailsScreenViewModel {
        DetailsScreenViewModel(
            resolveResources: ResolvePlaybackResources(resolver: resourceResolver),
            fallbackURL: { [self] item in self.playbackURL(for: item) },
            profileID: profileID
        )
    }

    func makePlayerScreenViewModel(selection: PlaybackSelection) -> PlayerScreenViewModel {
        PlayerScreenViewModel(
            selection: selection,
            loadProgress: LoadPlaybackProgress(store: progressStore),
            saveProgress: SavePlaybackProgress(store: progressStore)
        )
    }

    func makeLoginViewModel(
        onAuthenticated: @MainActor @Sendable @escaping (UserAccount) -> Void
    ) -> LoginViewModel {
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
            loadAccount: LoadCurrentAccount(repository: authRepository),
            getWatchHistory: GetWatchHistory(store: progressStore),
            clearWatchHistory: ClearWatchHistory(store: progressStore),
            getWatchlist: GetWatchlist(store: watchlistStore),
            onSignOut: onSignOut
        )
    }
}
