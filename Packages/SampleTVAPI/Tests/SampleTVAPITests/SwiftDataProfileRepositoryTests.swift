import Foundation
import SampleTVDomain
import SwiftData
import Testing
@testable import SampleTVAPI

@Suite struct SwiftDataProfileRepositoryTests {
    private func makeRepository() throws -> SwiftDataProfileRepository {
        try SwiftDataProfileRepository(inMemory: true)
    }

    @Test func currentProfileDefaultsToMain() async throws {
        let repository = try makeRepository()
        let profile = try await repository.currentProfile()
        #expect(profile.id == "main")
        #expect(profile.name == "Main")
        #expect(profile.isMain == true)
    }

    @Test func profilesSeedsHouseholdProfiles() async throws {
        let repository = try makeRepository()
        let profiles = try await repository.profiles()
        #expect(profiles.count == 3)
        #expect(profiles.first?.id == "main")
        #expect(profiles.contains { $0.id == "kids" })
        #expect(profiles.contains { $0.id == "guest" })
    }

    @Test func preferencesDefaultsToMovieAndAutoplay() async throws {
        let repository = try makeRepository()
        let preferences = try await repository.preferences(for: "main")
        #expect(preferences.defaultKind == .movie)
        #expect(preferences.autoplayTrailers == true)
    }

    @Test func updatePreferencesPersistsPerProfile() async throws {
        let repository = try makeRepository()
        let newPrefs = UserPreferences(defaultKind: .tv, autoplayTrailers: false)
        try await repository.updatePreferences(newPrefs, for: "main")

        let updatedPrefs = try await repository.preferences(for: "main")
        #expect(updatedPrefs.defaultKind == .tv)
        #expect(updatedPrefs.autoplayTrailers == false)

        let kidsPrefs = try await repository.preferences(for: "kids")
        #expect(kidsPrefs.defaultKind == .movie)
        #expect(kidsPrefs.autoplayTrailers == true)
    }

    @Test func switchProfileUpdatesCurrentProfile() async throws {
        let repository = try makeRepository()
        try await repository.switchProfile(to: "kids")
        let current = try await repository.currentProfile()
        #expect(current.id == "kids")
        #expect(current.name == "Kids")
    }
}
