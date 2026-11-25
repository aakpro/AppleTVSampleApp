import Foundation
import SampleTVDomain

/// Mock implementation of ProfileRepository for use in SampleTVAPI
public final class MockProfileRepository: ProfileRepository {
    public init() {}
    
    public func currentProfile() async throws -> ViewerProfile {
        // Return a simple mock profile 
        return ViewerProfile(id: "main", name: "Main", isMain: true)
    }
    
    public func profiles() async throws -> [ViewerProfile] {
        return [
            ViewerProfile(id: "main", name: "Main", isMain: true),
            ViewerProfile(id: "kids", name: "Kids", isMain: false),
            ViewerProfile(id: "guest", name: "Guest", isMain: false)
        ]
    }
    
    public func preferences(for profileID: String) async throws -> UserPreferences {
        // Return default preferences for any profile
        return UserPreferences()
    }
    
    public func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {
        // Mock implementation - no persistence in this simple version
    }
    
    public func switchProfile(to profileID: String) async throws {
        // Mock implementation - no actual switching in this simple version
    }
}