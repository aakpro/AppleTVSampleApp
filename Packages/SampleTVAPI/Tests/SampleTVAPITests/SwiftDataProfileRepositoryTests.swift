import Foundation
import Testing
import SwiftData
@testable import SampleTVAPI
@testable import SampleTVDomain

@Suite struct SwiftDataProfileRepositoryTests {
    private var repository: SwiftDataProfileRepository!
    
    init() {
        // Initialize with in-memory database for testing
        do {
            self.repository = try SwiftDataProfileRepository(inMemory: true)
        } catch {
            #expect(false, "Failed to initialize repository: \(error)")
        }
    }
    
    @Test func testCurrentProfile() async throws {
        let profile = try await repository.currentProfile()
        #expect(profile.id == "main")
        #expect(profile.name == "Main")
        #expect(profile.isMain == true)
    }
    
    @Test func testProfiles() async throws {
        let profiles = try await repository.profiles()
        #expect(!profiles.isEmpty)
        #expect(profiles.first?.id == "main")
    }
    
    @Test func testPreferences() async throws {
        let preferences = try await repository.preferences(for: "main")
        #expect(preferences.defaultKind == .movie)
        #expect(preferences.autoplayTrailers == true)
    }
    
    @Test func testUpdatePreferences() async throws {
        var newPrefs = UserPreferences(defaultKind: .tv, autoplayTrailers: false)
        try await repository.updatePreferences(newPrefs, for: "main")
        
        let updatedPrefs = try await repository.preferences(for: "main")
        #expect(updatedPrefs.defaultKind == .tv)
        #expect(updatedPrefs.autoplayTrailers == false)
    }
    
    @Test func testSwitchProfile() async throws {
        try await repository.switchProfile(to: "kids")
        let profiles = try await repository.profiles()
        #expect(profiles.contains { $0.id == "kids" })
    }
}