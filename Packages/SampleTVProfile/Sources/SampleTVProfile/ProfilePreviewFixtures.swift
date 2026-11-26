#if DEBUG
import SampleTVDomain

@MainActor
extension ProfileViewModel {
    static var preview: ProfileViewModel {
        let profileRepo = PreviewProfileRepository()
        let authRepo = PreviewAuthRepository()
        let progressStore = PreviewProgressStore()
        let watchlistStore = PreviewWatchlistStore()
        return ProfileViewModel(
            getCurrentProfile: GetCurrentUserProfile(repository: profileRepo),
            getProfiles: GetProfiles(repository: profileRepo),
            getPreferences: GetUserPreferences(repository: profileRepo),
            updatePreferences: UpdateUserPreferences(repository: profileRepo),
            switchProfile: SwitchProfile(repository: profileRepo),
            signOut: SignOut(repository: authRepo),
            loadAccount: LoadCurrentAccount(repository: authRepo),
            getWatchHistory: GetWatchHistory(store: progressStore),
            clearWatchHistory: ClearWatchHistory(store: progressStore),
            getWatchlist: GetWatchlist(store: watchlistStore),
            onSignOut: {}
        )
    }
}

private struct PreviewProfileRepository: ProfileRepository {
    func currentProfile() async throws -> ViewerProfile {
        ViewerProfile(id: ViewerProfile.defaultID, name: "Main", isMain: true)
    }

    func profiles() async throws -> [ViewerProfile] {
        [
            ViewerProfile(id: ViewerProfile.defaultID, name: "Main", isMain: true),
            ViewerProfile(id: "kids", name: "Kids", isMain: false),
            ViewerProfile(id: "guest", name: "Guest", isMain: false)
        ]
    }

    func preferences(for profileID: String) async throws -> UserPreferences {
        UserPreferences()
    }

    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {}

    func switchProfile(to profileID: String) async throws {}
}

private struct PreviewAuthRepository: AuthRepository {
    func signIn(email: String, password: String) async throws -> UserAccount {
        UserAccount(
            id: "preview",
            email: email,
            displayName: "Preview",
            avatarSystemName: "person.circle.fill",
            isDemo: false,
            createdAt: .now
        )
    }

    func signInDemo() async throws -> UserAccount {
        UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle.fill",
            isDemo: true,
            createdAt: .now
        )
    }

    func signOut() async {}

    func currentAccount() async -> UserAccount? { nil }
}

private struct PreviewProgressStore: PlaybackProgressStore {
    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? { nil }
    func saveProgress(_ progress: PlaybackProgress) async throws {}
    func clearProgress(for mediaID: MediaID, profileID: String) async throws {}
    func clearAllProgress(for profileID: String) async throws {}
    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] { [] }
}

private struct PreviewWatchlistStore: WatchlistStore {
    func items(for profileID: String) async throws -> [MediaItem] {
        [
            MediaItem(
                id: MediaID(kind: .movie, value: 603),
                title: "The Matrix",
                releaseYear: 1999
            )
        ]
    }

    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool { false }
    func add(_ item: MediaItem, to profileID: String) async throws {}
    func remove(_ mediaID: MediaID, from profileID: String) async throws {}
    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool { false }
}
#endif
