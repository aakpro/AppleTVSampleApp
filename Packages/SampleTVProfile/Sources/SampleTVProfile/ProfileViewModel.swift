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
    private let loadAccountUseCase: LoadCurrentAccount?
    private let getWatchHistoryUseCase: GetWatchHistory
    private let clearWatchHistoryUseCase: ClearWatchHistory
    private let getWatchlistUseCase: GetWatchlist?
    private let onSignOut: @MainActor @Sendable () -> Void

    public private(set) var currentProfile: ViewerProfile?
    public private(set) var profiles: [ViewerProfile] = []
    public private(set) var preferences = UserPreferences()
    public private(set) var watchHistoryCount = 0
    public private(set) var watchlistItems: [MediaItem] = []
    public private(set) var account: UserAccount?
    public private(set) var errorMessage: String?

    public init(
        getCurrentProfile: GetCurrentUserProfile,
        getProfiles: GetProfiles,
        getPreferences: GetUserPreferences,
        updatePreferences: UpdateUserPreferences,
        switchProfile: SwitchProfile,
        signOut: SignOut,
        loadAccount: LoadCurrentAccount? = nil,
        getWatchHistory: GetWatchHistory,
        clearWatchHistory: ClearWatchHistory,
        getWatchlist: GetWatchlist? = nil,
        onSignOut: @MainActor @Sendable @escaping () -> Void
    ) {
        self.getCurrentProfile = getCurrentProfile
        self.getProfiles = getProfiles
        self.getPreferences = getPreferences
        self.updatePreferencesUseCase = updatePreferences
        self.switchProfileUseCase = switchProfile
        self.signOutUseCase = signOut
        self.loadAccountUseCase = loadAccount
        self.getWatchHistoryUseCase = getWatchHistory
        self.clearWatchHistoryUseCase = clearWatchHistory
        self.getWatchlistUseCase = getWatchlist
        self.onSignOut = onSignOut
    }

    public func load() async {
        errorMessage = nil
        do {
            let profile = try await getCurrentProfile()
            currentProfile = profile
            if let loadAccountUseCase {
                account = await loadAccountUseCase()
            }
            profiles = try await getProfiles()
            preferences = try await getPreferences(profileID: profile.id)
            let progressItems = try await getWatchHistoryUseCase(for: profile.id, maxCount: 100)
            watchHistoryCount = progressItems.count
            try await loadWatchlist(for: profile.id)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func updatePreferences(_ newPreferences: UserPreferences) async {
        let profileID = currentProfile?.id ?? ViewerProfile.defaultID
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
            let progressItems = try await getWatchHistoryUseCase(for: profile.id, maxCount: 100)
            watchHistoryCount = progressItems.count
            try await loadWatchlist(for: profile.id)
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadWatchlist(for profileID: String) async throws {
        guard let getWatchlistUseCase else {
            watchlistItems = []
            return
        }
        do {
            watchlistItems = try await getWatchlistUseCase(for: profileID)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            watchlistItems = []
            throw error
        }
    }

    public func clearWatchHistory() async {
        do {
            let profileID = currentProfile?.id ?? ViewerProfile.defaultID
            try await clearWatchHistoryUseCase(for: profileID)
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

    public func clearError() {
        errorMessage = nil
    }
}
