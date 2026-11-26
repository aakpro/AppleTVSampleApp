import Foundation
import SampleTVDomain
import SampleTVPersistence
import Testing

@Suite("MockAuthRepository Tests")
struct MockAuthRepositoryTests {
    private func makeRepository(
        suite: String = "com.sampletv.auth.tests.\(UUID().uuidString)"
    ) -> MockAuthRepository {
        UserDefaults.standard.removePersistentDomain(forName: suite)
        return MockAuthRepository(sessionStore: UserDefaultsSessionStore(suiteName: suite))
    }

    @Test("SignIn with empty fields throws AuthError.emptyFields")
    func signInEmptyFields() async {
        let repository = makeRepository()
        await #expect(throws: AuthError.emptyFields) {
            _ = try await repository.signIn(email: "", password: "")
        }
    }

    @Test("SignIn with invalid email format throws AuthError.invalidCredentials")
    func signInInvalidEmail() async {
        let repository = makeRepository()
        await #expect(throws: AuthError.invalidCredentials) {
            _ = try await repository.signIn(email: "invalid-email", password: "password")
        }
    }

    @Test("SignIn with password less than 4 characters throws AuthError.invalidCredentials")
    func signInShortPassword() async {
        let repository = makeRepository()
        await #expect(throws: AuthError.invalidCredentials) {
            _ = try await repository.signIn(email: "user@example.com", password: "123")
        }
    }

    @Test("SignIn with valid credentials works correctly")
    func signInValidCredentials() async throws {
        let repository = makeRepository()
        let account = try await repository.signIn(email: "user@example.com", password: "password123")

        #expect(account.email == "user@example.com")
        #expect(account.displayName == "user")
        #expect(account.isDemo == false)
    }

    @Test("SignInDemo works correctly")
    func signInDemo() async throws {
        let repository = makeRepository()
        let account = try await repository.signInDemo()

        #expect(account.email == "demo@sampletv.app")
        #expect(account.displayName == "Alex Mercer")
        #expect(account.isDemo == true)
    }

    @Test("SignOut clears persisted account")
    func signOut() async throws {
        let repository = makeRepository()
        _ = try await repository.signIn(email: "user@example.com", password: "password123")
        await repository.signOut()

        let currentAccount = await repository.currentAccount()
        #expect(currentAccount == nil)
    }

    @Test("Account persists across repository instances")
    func persistence() async throws {
        let suite = "com.sampletv.auth.tests.\(UUID().uuidString)"
        let repository1 = MockAuthRepository(sessionStore: UserDefaultsSessionStore(suiteName: suite))
        let repository2 = MockAuthRepository(sessionStore: UserDefaultsSessionStore(suiteName: suite))

        let account = try await repository1.signIn(email: "user@example.com", password: "password123")
        let retrievedAccount = await repository2.currentAccount()
        #expect(retrievedAccount?.email == account.email)
    }
}
