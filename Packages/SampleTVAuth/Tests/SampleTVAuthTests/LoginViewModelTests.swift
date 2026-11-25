import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVAuth

@MainActor
@Suite("LoginViewModel Tests")
struct LoginViewModelTests {
    @Test("Transitions from idle to authenticated when sign in succeeds")
    func signInSuccess() async {
        var authenticatedEmail: String?
        let viewModel = LoginViewModel(
            signIn: SignIn(repository: StubAuthRepository()),
            signInDemo: SignInDemo(repository: StubAuthRepository()),
            onAuthenticated: { authenticatedEmail = $0.email }
        )

        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        await viewModel.submit()

        guard case .authenticated(let account) = viewModel.state else {
            Issue.record("Expected authenticated state, got \(viewModel.state)")
            return
        }
        #expect(account.email == "user@example.com")
        #expect(authenticatedEmail == "user@example.com")
    }

    @Test("Transitions from idle to failed when sign in fails")
    func signInFailure() async {
        let viewModel = LoginViewModel(
            signIn: SignIn(repository: StubFailingAuthRepository()),
            signInDemo: SignInDemo(repository: StubFailingAuthRepository()),
            onAuthenticated: { _ in }
        )

        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        await viewModel.submit()

        #expect(viewModel.state == .failed(.invalidCredentials))
    }

    @Test("Transitions from idle to authenticated when demo sign in succeeds")
    func signInDemoSuccess() async {
        let viewModel = LoginViewModel(
            signIn: SignIn(repository: StubAuthRepository()),
            signInDemo: SignInDemo(repository: StubAuthRepository()),
            onAuthenticated: { _ in }
        )

        await viewModel.continueAsDemo()

        guard case .authenticated(let account) = viewModel.state else {
            Issue.record("Expected authenticated state, got \(viewModel.state)")
            return
        }
        #expect(account.isDemo)
    }
}

private struct StubAuthRepository: AuthRepository {
    func currentAccount() async -> UserAccount? { nil }

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

    func signOut() async {}
}

private struct StubFailingAuthRepository: AuthRepository {
    func currentAccount() async -> UserAccount? { nil }
    func signIn(email: String, password: String) async throws -> UserAccount { throw AuthError.invalidCredentials }
    func signInDemo() async throws -> UserAccount { throw AuthError.invalidCredentials }
    func signOut() async {}
}
