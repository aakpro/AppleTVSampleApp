import Foundation
import Testing
@testable import SampleTVDomain

@Suite struct ProfileTests {
    @Test func viewerProfileInit() {
        let profile = ViewerProfile(id: "main", name: "Main", isMain: true)
        #expect(profile.id == "main")
        #expect(profile.name == "Main")
        #expect(profile.isMain == true)
    }

    @Test func userPreferencesInitDefault() {
        let preferences = UserPreferences()
        #expect(preferences.defaultKind == .movie)
        #expect(preferences.autoplayTrailers == true)
    }

    @Test func userPreferencesInitCustom() {
        let preferences = UserPreferences(defaultKind: .tv, autoplayTrailers: false)
        #expect(preferences.defaultKind == .tv)
        #expect(preferences.autoplayTrailers == false)
    }

    @Test func profileUseCasesDelegateToRepository() async throws {
        let repository = DomainStubProfileRepository()
        let getCurrent = GetCurrentUserProfile(repository: repository)
        let getProfiles = GetProfiles(repository: repository)
        let getPrefs = GetUserPreferences(repository: repository)
        let updatePrefs = UpdateUserPreferences(repository: repository)
        let switchProfile = SwitchProfile(repository: repository)

        #expect(try await getCurrent().id == "main")
        #expect(try await getProfiles().count == 2)

        try await switchProfile(to: "kids")
        #expect(try await getCurrent().id == "kids")

        let customPrefs = UserPreferences(defaultKind: .tv, autoplayTrailers: false)
        try await updatePrefs(customPrefs, for: "kids")
        #expect(try await getPrefs(profileID: "kids") == customPrefs)
    }

    @Test func playbackProgressWatchedAndLegacyDecoding() throws {
        let unwatched = PlaybackProgress(mediaID: MediaID(kind: .movie, value: 1), position: 150, duration: 600)
        #expect(unwatched.isWatched == false)

        let zeroDuration = PlaybackProgress(mediaID: MediaID(kind: .movie, value: 2), position: 10, duration: 0)
        #expect(zeroDuration.isWatched == false)

        let completed = PlaybackProgress(mediaID: MediaID(kind: .movie, value: 3), position: 570, duration: 600)
        #expect(completed.isWatched == true)

        let encoded = try JSONEncoder().encode(unwatched)
        var raw = try JSONSerialization.jsonObject(with: encoded) as? [String: Any] ?? [:]
        raw.removeValue(forKey: "profileID")
        let legacyData = try JSONSerialization.data(withJSONObject: raw)
        let decoded = try JSONDecoder().decode(PlaybackProgress.self, from: legacyData)
        #expect(decoded.profileID == ViewerProfile.defaultID)
        #expect(decoded.mediaID == unwatched.mediaID)
    }
}

private actor DomainStubProfileRepository: ProfileRepository {
    private var activeID = "main"
    private let list = [
        ViewerProfile(id: "main", name: "Main", isMain: true),
        ViewerProfile(id: "kids", name: "Kids", isMain: false)
    ]
    private var prefs: [String: UserPreferences] = [:]

    func currentProfile() async throws -> ViewerProfile {
        list.first { $0.id == activeID } ?? list[0]
    }

    func profiles() async throws -> [ViewerProfile] { list }

    func preferences(for profileID: String) async throws -> UserPreferences {
        prefs[profileID] ?? UserPreferences()
    }

    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {
        prefs[profileID] = preferences
    }

    func switchProfile(to profileID: String) async throws {
        activeID = profileID
    }
}
