import Foundation

// MARK: - Profile Repository Protocol

public protocol ProfileRepository: Sendable {
    func currentProfile() async throws -> ViewerProfile
    func profiles() async throws -> [ViewerProfile]
    func preferences(for profileID: String) async throws -> UserPreferences
    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws
    func switchProfile(to profileID: String) async throws
}
