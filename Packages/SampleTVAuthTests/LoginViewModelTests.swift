import Testing
import SampleTVDomain
import SampleTVAuth

@Suite("LoginViewModel Tests")
struct LoginViewModelTests {
    
    @Test("ViewModel transitions from idle to authenticated state when sign in succeeds")
    func signInSuccess() async throws {
        let viewModel = LoginViewModel(
            signIn: SignIn(repository: StubAuthRepository()),
            signInDemo: SignInDemo(repository: StubAuthRepository()),
            onAuthenticated: { _ in }
        )
        
        // Set up test values
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // Submit sign in
        viewModel.submit()
        
        // Wait for async operation
        try await Task.sleep(for: .seconds(0.1))
        
        // Verify state transition
        #expect(viewModel.state is LoginViewModel.State.authenticated)
    }
    
    @Test("ViewModel transitions from idle to failed state when sign in fails")
    func signInFailure() async throws {
        let viewModel = LoginViewModel(
            signIn: SignIn(repository: StubFailingAuthRepository()),
            signInDemo: SignInDemo(repository: StubFailingAuthRepository()),
            onAuthenticated: { _ in }
        )
        
        // Set up test values
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        
        // Submit sign in
        viewModel.submit()
        
        // Wait for async operation
        try await Task.sleep(for: .seconds(0.1))
        
        // Verify state transition to failed
        #expect(viewModel.state is LoginViewModel.State.failed)
    }
    
    @Test("ViewModel transitions from idle to authenticated when demo sign in succeeds")
    func signInDemoSuccess() async throws {
        let viewModel = LoginViewModel(
            signIn: SignIn(repository: StubAuthRepository()),
            signInDemo: SignInDemo(repository: StubAuthRepository()),
            onAuthenticated: { _ in }
        )
        
        // Submit demo sign in
        viewModel.continueAsDemo()
        
        // Wait for async operation
        try await Task.sleep(for: .seconds(0.1))
        
        // Verify state transition to authenticated
        #expect(viewModel.state is LoginViewModel.State.authenticated)
    }
}

// MARK: - Stub Implementations

private class StubAuthRepository: AuthRepository {
    func currentAccount() async -> UserAccount? {
        nil
    }
    
    func signIn(email: String, password: String) async throws -> UserAccount {
        UserAccount(
            id: UUID().uuidString,
            email: email,
            displayName: email.components(separatedBy: "@").first ?? "User",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: Date()
        )
    }
    
    func signInDemo() async throws -> UserAccount {
        UserAccount(
            id: "demo_user",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: Date()
        )
    }
    
    func signOut() async {
        // No-op
    }
}

private class StubFailingAuthRepository: AuthRepository {
    func currentAccount() async -> UserAccount? {
        nil
    }
    
    func signIn(email: String, password: String) async throws -> UserAccount {
        throw AuthError.invalidCredentials
    }
    
    func signInDemo() async throws -> UserAccount {
        throw AuthError.invalidCredentials
    }
    
    func signOut() async {
        // No-op
    }
}