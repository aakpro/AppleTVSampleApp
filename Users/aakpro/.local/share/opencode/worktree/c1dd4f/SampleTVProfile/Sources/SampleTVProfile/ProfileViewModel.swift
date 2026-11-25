import Foundation
import Observation
import SampleTVDomain
import SampleTVPlaybackProgress

@MainActor
public final class ProfileViewModel: ObservableObject {
    private let getCurrentProfile: GetCurrentUserProfile
    private let getPreferences: GetUserPreferences
    private let updatePreferences: UpdateUserPreferences
    private let switchProfile: SwitchProfile
    private let progressStore: any PlaybackProgressStore
    
    @Published public var currentProfile: ViewerProfile?
    @Published public var profiles: [ViewerProfile] = []
    @Published public var preferences: UserPreferences = UserPreferences()
    @Published public var watchHistoryCount: Int = 0
    
    public init(
        getCurrentProfile: GetCurrentUserProfile,
        getPreferences: GetUserPreferences,
        updatePreferences: UpdateUserPreferences,
        switchProfile: SwitchProfile,
        progressStore: any PlaybackProgressStore
    ) {
        self.getCurrentProfile = getCurrentProfile
        self.getPreferences = getPreferences
        self.updatePreferences = updatePreferences
        self.switchProfile = switchProfile
        self.progressStore = progressStore
        
        Task {
            await loadProfile()
            await loadPreferences()
            await loadWatchHistoryCount()
        }
    }
    
    private func loadProfile() async {
        do {
            currentProfile = try await getCurrentProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
    }
    
    private func loadPreferences() async {
        do {
            preferences = try await getPreferences()
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }
    
    private func loadWatchHistoryCount() async {
        do {
            let progressItems = try await progressStore.recentlyWatched(maxCount: 100)
            watchHistoryCount = progressItems.count
        } catch {
            print("Failed to load watch history count: \(error)")
        }
    }
    
    public func updatePreferences(_ newPreferences: UserPreferences) async {
        do {
            try await updatePreferences(newPreferences)
            preferences = newPreferences
        } catch {
            print("Failed to update preferences: \(error)")
        }
    }
    
    public func switchToProfile(_ profileID: String) async {
        do {
            try await switchProfile(to: profileID)
            await loadProfile()
        } catch {
            print("Failed to switch profile: \(error)")
        }
    }
    
    public func clearWatchHistory() async {
        do {
            // For this mock implementation, we can't really call clearProgress() without a specific mediaID
            // In a real implementation, you'd want to clear the entire history, but not supported by current API
            let progressItems = try await progressStore.recentlyWatched(maxCount: 100)
            watchHistoryCount = 0 // Just reset the displayed count
        } catch {
            print("Failed to clear watch history: \(error)")
        }
    }
}