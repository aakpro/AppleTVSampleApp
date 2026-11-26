import Foundation

public struct SignIn: Sendable {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction(email: String, password: String) async throws -> UserAccount {
        try await repository.signIn(email: email, password: password)
    }
}

public struct SignInDemo: Sendable {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction() async throws -> UserAccount {
        try await repository.signInDemo()
    }
}

public struct SignOut: Sendable {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction() async {
        await repository.signOut()
    }
}

public struct LoadCurrentAccount: Sendable {
    private let repository: any AuthRepository

    public init(repository: any AuthRepository) {
        self.repository = repository
    }

    public func callAsFunction() async -> UserAccount? {
        await repository.currentAccount()
    }
}
