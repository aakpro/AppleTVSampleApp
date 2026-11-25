import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVProfile

@MainActor
@Suite struct ProfileViewModelTests {
    @Test func loadPopulatesProfilePreferencesAndHistoryCount() async {
        let profileRepo = StubProfileRepository()
        let authRepo = StubAuthRepository()
        let progressStore = StubProgressStore(items: [
            PlaybackProgress(mediaID: MediaID(kind: .movie, value: 1), position: 10, duration: 100),
            PlaybackProgress(mediaID: MediaID(kind: .tv, value: 2), position: 20, duration: 100)
        ])

        let viewModel = makeViewModel(
            profileRepo: profileRepo,
            authRepo: authRepo,
            progressStore: progressStore
        )

        await viewModel.load()

        #expect(viewModel.currentProfile?.id == "main")
        #expect(viewModel.profiles.count == 2)
        #expect(viewModel.preferences.defaultKind == .movie)
        #expect(viewModel.watchHistoryCount == 2)
    }

    @Test func switchToProfileUpdatesCurrentProfileAndPreferences() async {
        let profileRepo = StubProfileRepository()
        let viewModel = makeViewModel(profileRepo: profileRepo)

        await viewModel.load()
        await viewModel.switchToProfile("kids")

        #expect(viewModel.currentProfile?.id == "kids")
        #expect(viewModel.preferences.defaultKind == .tv)
        #expect(viewModel.preferences.autoplayTrailers == false)
    }

    @Test func updatePreferencesPersistsForCurrentProfile() async {
        let profileRepo = StubProfileRepository()
        let viewModel = makeViewModel(profileRepo: profileRepo)

        await viewModel.load()
        let updated = UserPreferences(defaultKind: .tv, autoplayTrailers: false)
        await viewModel.updatePreferences(updated)

        #expect(viewModel.preferences == updated)
        let stored = try? await profileRepo.preferences(for: "main")
        #expect(stored == updated)
    }

    @Test func clearWatchHistoryRemovesAllItems() async {
        let progressStore = StubProgressStore(items: [
            PlaybackProgress(mediaID: MediaID(kind: .movie, value: 10), position: 30, duration: 120)
        ])
        let viewModel = makeViewModel(progressStore: progressStore)

        await viewModel.load()
        #expect(viewModel.watchHistoryCount == 1)

        await viewModel.clearWatchHistory()
        #expect(viewModel.watchHistoryCount == 0)
        let remaining = try? await progressStore.recentlyWatched(maxCount: 10)
        #expect(remaining?.isEmpty == true)
    }

    @Test func signOutCallsRepositoryAndCallback() async {
        let authRepo = StubAuthRepository()
        var didSignOut = false
        let viewModel = makeViewModel(authRepo: authRepo, onSignOut: {
            didSignOut = true
        })

        await viewModel.signOut()

        #expect(await authRepo.didCallSignOut == true)
        #expect(didSignOut == true)
    }

    @Test func loadLoadsWatchlistItems() async {
        let profileRepo = StubProfileRepository()
        let savedItem = MediaItem(
            id: MediaID(kind: .movie, value: 123),
            title: "Test Movie",
            releaseYear: 2023,
            rating: 8.5,
            posterPath: "/path.jpg"
        )
        let watchlistStore = StubWatchlistStore(itemsByProfile: ["main": [savedItem]])
        let viewModel = makeViewModel(
            profileRepo: profileRepo,
            watchlistStore: watchlistStore
        )

        await viewModel.load()

        #expect(viewModel.watchlistItems == [savedItem])
    }

    @Test func loadLeavesWatchlistEmptyWithoutStore() async {
        let viewModel = makeViewModel()

        await viewModel.load()

        #expect(viewModel.watchlistItems.isEmpty)
    }

    @Test func switchToProfileLoadsWatchlistItemsForNewProfile() async {
        let profileRepo = StubProfileRepository()
        let mainMovie = MediaItem(
            id: MediaID(kind: .movie, value: 123),
            title: "Main Profile Movie",
            releaseYear: 2023,
            rating: 8.5,
            posterPath: "/main.jpg"
        )
        let kidsShow = MediaItem(
            id: MediaID(kind: .tv, value: 456),
            title: "Kids Profile Show",
            releaseYear: 2023,
            rating: 8.5,
            posterPath: "/kids.jpg"
        )
        let watchlistStore = StubWatchlistStore(itemsByProfile: [
            "main": [mainMovie],
            "kids": [kidsShow]
        ])
        let viewModel = makeViewModel(
            profileRepo: profileRepo,
            watchlistStore: watchlistStore
        )

        await viewModel.load()
        #expect(viewModel.watchlistItems == [mainMovie])

        await viewModel.switchToProfile("kids")
        #expect(viewModel.watchlistItems == [kidsShow])
    }

    @Test func switchToProfileWithEmptyWatchlistClearsItems() async {
        let profileRepo = StubProfileRepository()
        let mainMovie = MediaItem(
            id: MediaID(kind: .movie, value: 123),
            title: "Main Profile Movie",
            releaseYear: 2023
        )
        let watchlistStore = StubWatchlistStore(itemsByProfile: ["main": [mainMovie]])
        let viewModel = makeViewModel(
            profileRepo: profileRepo,
            watchlistStore: watchlistStore
        )

        await viewModel.load()
        #expect(viewModel.watchlistItems == [mainMovie])

        await viewModel.switchToProfile("kids")
        #expect(viewModel.watchlistItems.isEmpty)
    }

    private func makeViewModel(
        profileRepo: StubProfileRepository = StubProfileRepository(),
        authRepo: StubAuthRepository = StubAuthRepository(),
        progressStore: StubProgressStore = StubProgressStore(),
        watchlistStore: StubWatchlistStore? = nil,
        onSignOut: @MainActor @Sendable @escaping () -> Void = {}
    ) -> ProfileViewModel {
        ProfileViewModel(
            getCurrentProfile: GetCurrentUserProfile(repository: profileRepo),
            getProfiles: GetProfiles(repository: profileRepo),
            getPreferences: GetUserPreferences(repository: profileRepo),
            updatePreferences: UpdateUserPreferences(repository: profileRepo),
            switchProfile: SwitchProfile(repository: profileRepo),
            signOut: SignOut(repository: authRepo),
            progressStore: progressStore,
            watchlistStore: watchlistStore,
            onSignOut: onSignOut
        )
    }
}

private actor StubProfileRepository: ProfileRepository {
    private var activeID = "main"
    private let allProfiles = [
        ViewerProfile(id: "main", name: "Main", isMain: true),
        ViewerProfile(id: "kids", name: "Kids", isMain: false)
    ]
    private var prefsByProfile: [String: UserPreferences] = [
        "main": UserPreferences(defaultKind: .movie, autoplayTrailers: true),
        "kids": UserPreferences(defaultKind: .tv, autoplayTrailers: false)
    ]

    func currentProfile() async throws -> ViewerProfile {
        allProfiles.first { $0.id == activeID } ?? allProfiles[0]
    }

    func profiles() async throws -> [ViewerProfile] {
        allProfiles
    }

    func preferences(for profileID: String) async throws -> UserPreferences {
        prefsByProfile[profileID] ?? UserPreferences()
    }

    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {
        prefsByProfile[profileID] = preferences
    }

    func switchProfile(to profileID: String) async throws {
        activeID = profileID
    }
}

private actor StubAuthRepository: AuthRepository {
    private(set) var didCallSignOut = false

    func signIn(email: String, password: String) async throws -> UserAccount {
        UserAccount(
            id: "1",
            email: email,
            displayName: "User",
            avatarSystemName: "person.circle.fill",
            isDemo: false,
            createdAt: .now
        )
    }

    func signInDemo() async throws -> UserAccount {
        UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Demo",
            avatarSystemName: "person.circle.fill",
            isDemo: true,
            createdAt: .now
        )
    }

    func signOut() async {
        didCallSignOut = true
    }

    func currentAccount() async -> UserAccount? { nil }
}

private actor StubProgressStore: PlaybackProgressStore {
    private var items: [MediaID: PlaybackProgress]

    init(items: [PlaybackProgress] = []) {
        var map: [MediaID: PlaybackProgress] = [:]
        for item in items {
            map[item.mediaID] = item
        }
        self.items = map
    }

    func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress? {
        items[mediaID]
    }

    func saveProgress(_ progress: PlaybackProgress) async throws {
        items[progress.mediaID] = progress
    }

    func clearProgress(for mediaID: MediaID) async throws {
        items.removeValue(forKey: mediaID)
    }

    func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress] {
        Array(items.values.prefix(maxCount))
    }
}

private actor StubWatchlistStore: WatchlistStore {
    private var itemsByProfile: [String: [MediaItem]]

    init(itemsByProfile: [String: [MediaItem]] = [:]) {
        self.itemsByProfile = itemsByProfile
    }

    func items(for profileID: String) async throws -> [MediaItem] {
        itemsByProfile[profileID] ?? []
    }

    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool {
        (itemsByProfile[profileID] ?? []).contains { $0.id == mediaID }
    }

    func add(_ item: MediaItem, to profileID: String) async throws {
        var items = itemsByProfile[profileID] ?? []
        guard !items.contains(where: { $0.id == item.id }) else { return }
        items.append(item)
        itemsByProfile[profileID] = items
    }

    func remove(_ mediaID: MediaID, from profileID: String) async throws {
        var items = itemsByProfile[profileID] ?? []
        items.removeAll { $0.id == mediaID }
        itemsByProfile[profileID] = items
    }

    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool {
        if try await contains(item.id, in: profileID) {
            try await remove(item.id, from: profileID)
            return false
        } else {
            try await add(item, to: profileID)
            return true
        }
    }
}
