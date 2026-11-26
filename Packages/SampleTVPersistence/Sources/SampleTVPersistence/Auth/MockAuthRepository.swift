import Foundation
import SampleTVDomain

public actor MockAuthRepository: AuthRepository {
    private let sessionStore: any SessionStore

    public init(sessionStore: any SessionStore = KeychainSessionStore()) {
        self.sessionStore = sessionStore
    }

    public func currentAccount() async -> UserAccount? {
        guard let data = sessionStore.load() else { return nil }

        do {
            return try JSONDecoder().decode(UserAccount.self, from: data)
        } catch {
            sessionStore.clear()
            return nil
        }
    }

    public func signIn(email: String, password: String) async throws -> UserAccount {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedEmail.isEmpty || trimmedPassword.isEmpty {
            throw AuthError.emptyFields
        }

        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") || trimmedPassword.count < 4 {
            throw AuthError.invalidCredentials
        }

        let account = UserAccount(
            id: UUID().uuidString,
            email: trimmedEmail,
            displayName: trimmedEmail.components(separatedBy: "@").first ?? "User",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: Date()
        )

        let data = try JSONEncoder().encode(account)
        sessionStore.save(data)
        return account
    }

    public func signInDemo() async throws -> UserAccount {
        let account = UserAccount(
            id: "demo_user",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: Date()
        )

        let data = try JSONEncoder().encode(account)
        sessionStore.save(data)
        return account
    }

    public func signOut() async {
        sessionStore.clear()
    }
}
