#if DEBUG
import Foundation
import SampleTVDomain

@MainActor
extension LoginViewModel {
    static var preview: LoginViewModel {
        let repo = PreviewAuthRepository()
        return LoginViewModel(
            signIn: SignIn(repository: repo),
            signInDemo: SignInDemo(repository: repo),
            onAuthenticated: { _ in }
        )
    }
}

private struct PreviewAuthRepository: AuthRepository {
    func currentAccount() async -> UserAccount? { nil }

    func signIn(email: String, password: String) async throws -> UserAccount {
        UserAccount(
            id: "1",
            email: email,
            displayName: "Preview",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: .now
        )
    }

    func signInDemo() async throws -> UserAccount {
        UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: .now
        )
    }

    func signOut() async {}
}
#endif
