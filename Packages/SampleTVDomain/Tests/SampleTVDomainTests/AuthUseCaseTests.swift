import Foundation
import SampleTVDomain
import Testing

@Suite("Auth Use Case Tests")
struct AuthUseCaseTests {
    @Test("SignIn use case works correctly")
    func signIn() async throws {
        let stubRepository = StubAuthRepository()
        let signIn = SignIn(repository: stubRepository)

        let account = try await signIn(email: "test@example.com", password: "password123")
        #expect(account.email == "test@example.com")
    }

    @Test("SignInDemo use case works correctly")
    func signInDemo() async throws {
        let stubRepository = StubAuthRepository()
        let signInDemo = SignInDemo(repository: stubRepository)

        let account = try await signInDemo()
        #expect(account.isDemo == true)
    }

    @Test("SignOut use case clears the account")
    func signOut() async {
        let stubRepository = StubAuthRepository()
        let signOut = SignOut(repository: stubRepository)

        await signOut()

        let current = await stubRepository.currentAccount()
        #expect(current == nil)
    }

    @Test("LoadCurrentAccount use case returns current account")
    func loadCurrentAccount() async {
        let stubRepository = StubAuthRepository()
        let loadCurrentAccount = LoadCurrentAccount(repository: stubRepository)

        let account = await loadCurrentAccount()
        #expect(account?.isDemo == true)
    }
}

private actor StubAuthRepository: AuthRepository {
    var account: UserAccount?

    init() {
        account = UserAccount(
            id: "demo_user",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: Date()
        )
    }

    func currentAccount() async -> UserAccount? {
        account
    }

    func signIn(email: String, password: String) async throws -> UserAccount {
        let newAccount = UserAccount(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: Date()
        )
        account = newAccount
        return newAccount
    }

    func signInDemo() async throws -> UserAccount {
        if let account { return account }
        let newAccount = UserAccount(
            id: "demo_user",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: Date()
        )
        account = newAccount
        return newAccount
    }

    func signOut() async {
        account = nil
    }
}
