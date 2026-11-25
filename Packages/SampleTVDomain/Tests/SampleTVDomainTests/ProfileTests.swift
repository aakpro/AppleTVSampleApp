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
}