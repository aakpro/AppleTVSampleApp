import Foundation

// MARK: - Viewer Profile

public struct ViewerProfile: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let isMain: Bool

    public init(id: String, name: String, isMain: Bool) {
        self.id = id
        self.name = name
        self.isMain = isMain
    }
}

// MARK: - User Preferences

public struct UserPreferences: Codable, Hashable, Sendable {
    public var defaultKind: MediaKind
    public var autoplayTrailers: Bool

    public init(defaultKind: MediaKind = .movie, autoplayTrailers: Bool = true) {
        self.defaultKind = defaultKind
        self.autoplayTrailers = autoplayTrailers
    }
}

// MARK: - Profile Repository Protocol

public protocol ProfileRepository: Sendable {
    func currentProfile() async throws -> ViewerProfile
    func profiles() async throws -> [ViewerProfile]
    func preferences(for profileID: String) async throws -> UserPreferences
    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws
    func switchProfile(to profileID: String) async throws
}

// MARK: - Use Cases

public struct GetCurrentUserProfile: Sendable {
    private let repository: any ProfileRepository

    public init(repository: any ProfileRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> ViewerProfile {
        try await repository.currentProfile()
    }
}

public struct GetProfiles: Sendable {
    private let repository: any ProfileRepository

    public init(repository: any ProfileRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> [ViewerProfile] {
        try await repository.profiles()
    }
}

public struct GetUserPreferences: Sendable {
    private let repository: any ProfileRepository

    public init(repository: any ProfileRepository) {
        self.repository = repository
    }

    public func callAsFunction(profileID: String) async throws -> UserPreferences {
        try await repository.preferences(for: profileID)
    }
}

public struct UpdateUserPreferences: Sendable {
    private let repository: any ProfileRepository

    public init(repository: any ProfileRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ preferences: UserPreferences, for profileID: String) async throws {
        try await repository.updatePreferences(preferences, for: profileID)
    }
}

public struct SwitchProfile: Sendable {
    private let repository: any ProfileRepository

    public init(repository: any ProfileRepository) {
        self.repository = repository
    }

    public func callAsFunction(to profileID: String) async throws {
        try await repository.switchProfile(to: profileID)
    }
}
