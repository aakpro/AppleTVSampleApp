import Foundation
import SampleTVAPI
import SampleTVAuth
import SampleTVDiscovery
import SampleTVDomain
import SampleTVPersistence
import SampleTVProfile
import SampleTVSearch
import Testing
@testable import SampleTV

@MainActor
struct AppContainerTests {
    @Test func liveContainerInitializes() {
        let container = AppContainer.live()
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        #expect(container.playbackURL(for: item) == AppContainer.sampleStream)
    }

    @Test func factoriesWireWatchlistStoreAndProfileID() async throws {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let modelContainer = try PersistenceContainer.makeModelContainer(inMemory: true)
        let watchlistStore = SwiftDataWatchlistStore(modelContainer: modelContainer)
        try await watchlistStore.add(item, to: "kids")

        let profileRepository = SwiftDataProfileRepository(modelContainer: modelContainer)
        try await profileRepository.switchProfile(to: "kids")

        let sessionSuite = "AppContainerTests.\(UUID().uuidString)"
        let container = AppContainer(
            configuration: AppConfiguration(tmdbToken: "test-token"),
            repository: StubMediaRepository(item: item),
            progressStore: StubProgressStore(),
            authRepository: MockAuthRepository(sessionStore: TestUserDefaultsSessionStore(suiteName: sessionSuite)),
            profileRepository: profileRepository,
            resourceResolver: CatalogPlaybackResourceResolver(),
            watchlistStore: watchlistStore
        )

        let detailsVM = container.makeDetailsViewModel(for: item, profileID: "kids")
        await detailsVM.load()
        #expect(detailsVM.isInWatchlist == true)

        let defaultDetailsVM = container.makeDetailsViewModel(for: item)
        await defaultDetailsVM.load()
        #expect(defaultDetailsVM.isInWatchlist == false)

        let profileVM = container.makeProfileViewModel(onSignOut: {})
        await profileVM.load()
        #expect(profileVM.currentProfile?.id == "kids")
        #expect(profileVM.watchlistItems == [item])

        let discoveryVM = container.makeDiscoveryViewModel()
        await discoveryVM.reload()
        #expect(discoveryVM.kind == .movie)

        let searchVM = container.makeSearchViewModel()
        #expect(searchVM.text.isEmpty)

        var authed: UserAccount?
        let loginVM = container.makeLoginViewModel { authed = $0 }
        await loginVM.continueAsDemo()
        #expect(authed?.isDemo == true)
    }
}

private struct StubMediaRepository: MediaRepository {
    let item: MediaItem

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        ResultPage(items: [item], page: 1, totalPages: 1)
    }

    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        ResultPage(items: [item], page: 1, totalPages: 1)
    }

    func details(of id: MediaID) async throws -> MediaDetails {
        MediaDetails(item: item)
    }

    func genres(for kind: MediaKind) async throws -> [Genre] {
        [Genre(id: 28, name: "Action")]
    }
}

private struct StubProgressStore: PlaybackProgressStore {
    func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? { nil }
    func saveProgress(_ progress: PlaybackProgress) async throws {}
    func clearProgress(for mediaID: MediaID, profileID: String) async throws {}
    func clearAllProgress(for profileID: String) async throws {}
    func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] { [] }
}

private struct TestUserDefaultsSessionStore: SessionStore {
    private let suiteName: String
    private let key = "currentAccount"

    init(suiteName: String) {
        self.suiteName = suiteName
    }

    func load() -> Data? {
        (UserDefaults(suiteName: suiteName) ?? .standard).data(forKey: key)
    }

    func save(_ data: Data) {
        (UserDefaults(suiteName: suiteName) ?? .standard).set(data, forKey: key)
    }

    func clear() {
        (UserDefaults(suiteName: suiteName) ?? .standard).removeObject(forKey: key)
    }
}
