import Testing
import SampleTVDomain

@Suite("Auth Use Case Tests")
struct AuthUseCaseTests {
    
    @Test("SignIn use case works correctly")
    func signIn() async throws {
        // Create a stub repository that returns a demo account
        let stubRepository = StubAuthRepository()
        let signIn = SignIn(repository: stubRepository)
        
        let account = try await signIn(email: "test@example.com", password: "password123")
        
        #expect(account.email == "test@example.com")
    }
    
    @Test("SignInDemo use case works correctly")
    func signInDemo() async throws {
        // Create a stub repository that returns a demo account
        let stubRepository = StubAuthRepository()
        let signInDemo = SignInDemo(repository: stubRepository)
        
        let account = try await signInDemo()
        
        #expect(account.isDemo == true)
    }
    
    @Test("SignOut use case works correctly")
    func signOut() async throws {
        // Create a stub repository that returns a demo account
        let stubRepository = StubAuthRepository()
        let signOut = SignOut(repository: stubRepository)
        
        await signOut()
        
        // Verify that the account was cleared in the stub repository
        #expect(stubRepository.account == nil)
    }
    
    @Test("LoadCurrentAccount use case works correctly")
    func loadCurrentAccount() async throws {
        // Create a stub repository with a demo account
        let stubRepository = StubAuthRepository()
        let loadCurrentAccount = LoadCurrentAccount(repository: stubRepository)
        
        let account = await loadCurrentAccount()
        
        #expect(account?.isDemo == true)
    }
}

// MARK: - Stub Implementation

private class StubAuthRepository: AuthRepository {
    var account: UserAccount?
    
    init() {
        // Create a demo account for testing
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
        // Create a new account for successful sign in
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
        // Return demo account from the stub
        guard let account = account else {
            // Create a new one if needed
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
        return account
    }
    
    func signOut() async {
        account = nil
    }
}