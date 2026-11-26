import Foundation

public struct UserAccount: Codable, Hashable, Sendable {
    public let id: String
    public let email: String
    public let displayName: String
    public let avatarSystemName: String
    public let isDemo: Bool
    public let createdAt: Date

    public init(
        id: String,
        email: String,
        displayName: String,
        avatarSystemName: String,
        isDemo: Bool,
        createdAt: Date
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarSystemName = avatarSystemName
        self.isDemo = isDemo
        self.createdAt = createdAt
    }
}

public enum AuthError: Error, Equatable, Sendable {
    case emptyFields
    case invalidCredentials
    case sessionExpired
}
