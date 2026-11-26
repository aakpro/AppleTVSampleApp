import Foundation
import SampleTVDomain
import Testing
@testable import SampleTV

@MainActor
struct RootViewModelTests {
    @Test func loadSessionPopulatesAccountAndActiveProfileID() async {
        let account = UserAccount(
            id: "1",
            email: "viewer@sampletv.app",
            displayName: "Viewer",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: .now
        )
        let viewModel = RootViewModel(
            loadCurrentAccount: LoadCurrentAccount(repository: StubAuthRepository(account: account)),
            getCurrentProfile: GetCurrentUserProfile(repository: StubProfileRepository(activeID: "kids")),
            hasTMDBToken: true
        )

        await viewModel.loadSession()

        #expect(viewModel.sessionState == .signedIn(account))
        #expect(viewModel.authenticatedAccount == account)
        #expect(viewModel.activeProfileID == "kids")
    }

    @Test func sessionStateStartsCheckingAndTransitionsOnLoadAndSignOut() async {
        let signedOutVM = RootViewModel(
            loadCurrentAccount: LoadCurrentAccount(repository: StubAuthRepository(account: nil)),
            getCurrentProfile: GetCurrentUserProfile(repository: StubProfileRepository(activeID: "main")),
            hasTMDBToken: true
        )
        #expect(signedOutVM.sessionState == .checking)

        await signedOutVM.loadSession()
        #expect(signedOutVM.sessionState == .signedOut)
        #expect(signedOutVM.authenticatedAccount == nil)

        let account = UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: .now
        )
        await signedOutVM.didAuthenticate(account)
        #expect(signedOutVM.sessionState == .signedIn(account))

        signedOutVM.signOut()
        #expect(signedOutVM.sessionState == .signedOut)
        #expect(signedOutVM.authenticatedAccount == nil)
    }

    @Test func didAuthenticateAndSignOutManageSessionAndNavigationState() async {
        let account = UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: .now
        )
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let viewModel = RootViewModel(
            loadCurrentAccount: LoadCurrentAccount(repository: StubAuthRepository(account: nil)),
            getCurrentProfile: GetCurrentUserProfile(repository: StubProfileRepository(activeID: "kids")),
            hasTMDBToken: true
        )

        await viewModel.didAuthenticate(account)
        #expect(viewModel.authenticatedAccount == account)
        #expect(viewModel.activeProfileID == "kids")

        await viewModel.selectMedia(item)
        viewModel.selectCategory(kind: .movie, genre: Genre(id: 28, name: "Action"))
        #expect(viewModel.selection == item)
        #expect(
            viewModel.categoryDestination == CategoryDestination(
                kind: .movie,
                genre: Genre(id: 28, name: "Action")
            )
        )

        viewModel.signOut()
        #expect(viewModel.authenticatedAccount == nil)
        #expect(viewModel.selection == nil)
        #expect(viewModel.categoryDestination == nil)
    }
}

@MainActor
struct DetailsScreenViewModelTests {
    @Test func startPlaybackUsesResolvedResourceWhenAvailable() async throws {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix", genreIDs: [28])
        let resolvedURL = try #require(URL(string: "https://example.com/resolved.m3u8"))
        let fallbackURL = try #require(URL(string: "https://example.com/fallback.m3u8"))
        let resource = PlayableResource(url: resolvedURL, kind: .feature, title: "The Matrix", trackProgress: true)

        let viewModel = DetailsScreenViewModel(
            resolveResources: ResolvePlaybackResources(resolver: StubResolver(resources: [resource])),
            fallbackURL: { _ in fallbackURL },
            profileID: "kids"
        )

        await viewModel.startPlayback(for: item, kind: .feature)

        #expect(viewModel.playbackSelection?.resource.url == resolvedURL)
        #expect(viewModel.playbackSelection?.resource.title == "The Matrix")
        #expect(viewModel.playbackSelection?.resource.subtitle == "Full Feature")
        #expect(viewModel.playbackSelection?.profileID == "kids")
    }

    @Test func startPlaybackPreservesMovieAndTrailerTitles() async throws {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix", genreIDs: [28])
        let resolvedURL = try #require(URL(string: "https://example.com/resolved.m3u8"))
        let trailerURL = try #require(URL(string: "https://example.com/trailer.m3u8"))
        let fallbackURL = try #require(URL(string: "https://example.com/fallback.m3u8"))
        let featureResource = PlayableResource(
            url: resolvedURL,
            kind: .feature,
            title: "Generic Catalog Stream",
            subtitle: "Other Subtitle",
            trackProgress: true
        )
        let trailerResource = PlayableResource(
            url: trailerURL,
            kind: .trailer,
            title: "Generic Trailer Stream",
            trackProgress: false
        )

        let viewModel = DetailsScreenViewModel(
            resolveResources: ResolvePlaybackResources(
                resolver: StubResolver(resources: [featureResource, trailerResource])
            ),
            fallbackURL: { _ in fallbackURL }
        )

        await viewModel.startPlayback(for: item, kind: .feature)
        #expect(viewModel.playbackSelection?.resource.title == "The Matrix")
        #expect(viewModel.playbackSelection?.resource.subtitle == "Full Feature")

        await viewModel.startPlayback(for: item, kind: .trailer, trailerTitle: "Official Teaser")
        #expect(viewModel.playbackSelection?.resource.title == "Official Teaser")
        #expect(viewModel.playbackSelection?.resource.subtitle == "The Matrix")

        await viewModel.startPlayback(for: item, kind: .trailer)
        #expect(viewModel.playbackSelection?.resource.title == "The Matrix — Trailer")
        #expect(viewModel.playbackSelection?.resource.subtitle == "The Matrix")
    }

    @Test func startPlaybackFallsBackToFallbackURLWhenEmpty() async throws {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let fallbackURL = try #require(URL(string: "https://example.com/fallback.m3u8"))

        let viewModel = DetailsScreenViewModel(
            resolveResources: ResolvePlaybackResources(resolver: StubResolver(resources: [])),
            fallbackURL: { _ in fallbackURL }
        )

        await viewModel.startPlayback(for: item, kind: .trailer)

        #expect(viewModel.playbackSelection?.resource.url == fallbackURL)
        #expect(viewModel.playbackSelection?.resource.trackProgress == false)
    }
}

@MainActor
struct PlayerScreenViewModelTests {
    @Test func loadLoadsUnwatchedInitialPositionAndIgnoresWatched() async throws {
        let url = try #require(URL(string: "https://example.com/stream.m3u8"))
        let unwatchedID = MediaID(kind: .movie, value: 1)
        let watchedID = MediaID(kind: .movie, value: 2)
        let store = StubNavigationProgressStore(records: [
            PlaybackProgress(mediaID: unwatchedID, position: 120, duration: 600, profileID: "kids"),
            PlaybackProgress(mediaID: watchedID, position: 580, duration: 600, profileID: "kids")
        ])

        let unwatchedVM = PlayerScreenViewModel(
            selection: PlaybackSelection(
                mediaID: unwatchedID,
                profileID: "kids",
                resource: PlayableResource(url: url, kind: .feature, title: "Feature", trackProgress: true)
            ),
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await unwatchedVM.load()
        #expect(unwatchedVM.isReady == true)
        #expect(unwatchedVM.initialPosition == 120)

        let watchedVM = PlayerScreenViewModel(
            selection: PlaybackSelection(
                mediaID: watchedID,
                profileID: "kids",
                resource: PlayableResource(url: url, kind: .feature, title: "Feature", trackProgress: true)
            ),
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await watchedVM.load()
        #expect(watchedVM.isReady == true)
        #expect(watchedVM.initialPosition == nil)
    }

    @Test func saveProgressPersistsFeatureAndSkipsTrailers() async throws {
        let url = try #require(URL(string: "https://example.com/stream.m3u8"))
        let store = StubNavigationProgressStore()

        let featureVM = PlayerScreenViewModel(
            selection: PlaybackSelection(
                mediaID: MediaID(kind: .movie, value: 10),
                profileID: "kids",
                resource: PlayableResource(url: url, kind: .feature, title: "Feature", trackProgress: true)
            ),
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await featureVM.saveProgress(position: 90, duration: 600)
        let savedFeature = try await store.loadProgress(
            for: MediaID(kind: .movie, value: 10),
            profileID: "kids"
        )
        #expect(savedFeature?.position == 90)

        let trailerVM = PlayerScreenViewModel(
            selection: PlaybackSelection(
                mediaID: MediaID(kind: .movie, value: 11),
                profileID: "kids",
                resource: PlayableResource(url: url, kind: .trailer, title: "Trailer", trackProgress: false)
            ),
            loadProgress: LoadPlaybackProgress(store: store),
            saveProgress: SavePlaybackProgress(store: store)
        )
        await trailerVM.saveProgress(position: 30, duration: 120)
        let savedTrailer = try await store.loadProgress(
            for: MediaID(kind: .movie, value: 11),
            profileID: "kids"
        )
        #expect(savedTrailer == nil)
    }
}

private struct StubAuthRepository: AuthRepository {
    let account: UserAccount?
    func currentAccount() async -> UserAccount? { account }
    func signIn(email: String, password: String) async throws -> UserAccount {
        account ?? UserAccount(
            id: "1",
            email: email,
            displayName: "User",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: .now
        )
    }
    func signInDemo() async throws -> UserAccount {
        account ?? UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Demo",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: .now
        )
    }
    func signOut() async {}
}

private struct StubProfileRepository: ProfileRepository {
    let activeID: String
    func currentProfile() async throws -> ViewerProfile {
        ViewerProfile(id: activeID, name: activeID.capitalized, isMain: activeID == ViewerProfile.defaultID)
    }
    func profiles() async throws -> [ViewerProfile] { [try await currentProfile()] }
    func preferences(for profileID: String) async throws -> UserPreferences { UserPreferences() }
    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {}
    func switchProfile(to profileID: String) async throws {}
}

private struct StubResolver: PlaybackResourceResolver {
    let resources: [PlayableResource]
    func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] { resources }
}

private actor StubNavigationProgressStore: PlaybackProgressStore {
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
