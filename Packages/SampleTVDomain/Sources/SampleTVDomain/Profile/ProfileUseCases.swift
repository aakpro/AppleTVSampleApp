import Foundation

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
