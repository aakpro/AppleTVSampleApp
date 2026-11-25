import Foundation
import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct LoginView: View {
    @State private var viewModel: LoginViewModel

    public init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Image(systemName: "play.rectangle.on.rectangle")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(.tint)

                Text("SampleTV")
                    .font(.largeTitle)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 24) {
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $viewModel.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .frame(maxWidth: 500)

            VStack(spacing: 16) {
                Button("Sign In") {
                    Task { await viewModel.submit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.state == .authenticating)

                Button("Continue with Demo Account") {
                    Task { await viewModel.continueAsDemo() }
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.state == .authenticating)
            }

            if case .failed(let error) = viewModel.state {
                Text(error.message)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if viewModel.state == .authenticating {
                ProgressView()
            }
        }
        .padding(60)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private extension AuthError {
    var message: String {
        switch self {
        case .emptyFields:
            "Email and password are required."
        case .invalidCredentials:
            "Invalid email or password."
        case .sessionExpired:
            "Session expired. Please sign in again."
        }
    }
}

#Preview {
    struct PreviewRepo: AuthRepository {
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
    let repo = PreviewRepo()
    return LoginView(
        viewModel: LoginViewModel(
            signIn: SignIn(repository: repo),
            signInDemo: SignInDemo(repository: repo),
            onAuthenticated: { _ in }
        )
    )
}
