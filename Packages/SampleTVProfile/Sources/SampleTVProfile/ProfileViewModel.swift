import Foundation
import Observation
import SampleTVDomain

@MainActor
@Observable
public final class ProfileViewModel {
    private let getCurrentProfile: GetCurrentUserProfile
    private let getProfiles: GetProfiles
    private let getPreferences: GetUserPreferences
    private let updatePreferencesUseCase: UpdateUserPreferences
    private let switchProfileUseCase: SwitchProfile
    private let signOutUseCase: SignOut
    private let progressStore: any PlaybackProgressStore
    private let watchlistStore: (any WatchlistStore)?
    private let onSignOut: @MainActor @Sendable () -> Void

    public private(set) var currentProfile: ViewerProfile?
    public private(set) var profiles: [ViewerProfile] = []
    public private(set) var preferences = UserPreferences()
    public private(set) var watchHistoryCount = 0
    public private(set) var watchlistItems: [MediaItem] = []
    public private(set) var errorMessage: String?

    public init(
        getCurrentProfile: GetCurrentUserProfile,
        getProfiles: GetProfiles,
        getPreferences: GetUserPreferences,
        updatePreferences: UpdateUserPreferences,
        switchProfile: SwitchProfile,
        signOut: SignOut,
        progressStore: any PlaybackProgressStore,
        watchlistStore: (any WatchlistStore)? = nil,
        onSignOut: @MainActor @Sendable @escaping () -> Void
    ) {
        self.getCurrentProfile = getCurrentProfile
        self.getProfiles = getProfiles
        self.getPreferences = getPreferences
        self.updatePreferencesUseCase = updatePreferences
        self.switchProfileUseCase = switchProfile
        self.signOutUseCase = signOut
        self.progressStore = progressStore
        self.watchlistStore = watchlistStore
        self.onSignOut = onSignOut
    }

    public func load() async {
        errorMessage = nil
        do {
            let profile = try await getCurrentProfile()
            currentProfile = profile
            profiles = try await getProfiles()
            preferences = try await getPreferences(profileID: profile.id)
            let progressItems = try await progressStore.recentlyWatched(maxCount: 100)
            watchHistoryCount = progressItems.count
            try await loadWatchlist(for: profile.id)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updatePreferences(_ newPreferences: UserPreferences) async {
        let profileID = currentProfile?.id ?? "main"
        do {
            try await updatePreferencesUseCase(newPreferences, for: profileID)
            preferences = newPreferences
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func switchToProfile(_ profileID: String) async {
        errorMessage = nil
        do {
            try await switchProfileUseCase(to: profileID)
            let profile = try await getCurrentProfile()
            currentProfile = profile
            preferences = try await getPreferences(profileID: profile.id)
            try await loadWatchlist(for: profile.id)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadWatchlist(for profileID: String) async throws {
        guard let watchlistStore else {
            watchlistItems = []
            return
        }
        do {
            watchlistItems = try await watchlistStore.items(for: profileID)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            watchlistItems = []
            throw error
        }
    }

    public func clearWatchHistory() async {
        do {
            let progressItems = try await progressStore.recentlyWatched(maxCount: 100)
            for item in progressItems {
                try await progressStore.clearProgress(for: item.mediaID)
            }
            watchHistoryCount = 0
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func signOut() async {
        await signOutUseCase()
        onSignOut()
    }
}
