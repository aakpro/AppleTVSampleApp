import Foundation
import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct LoginView: View {
    private enum FocusField: Hashable {
        case email
        case password
        case signIn
        case demo
    }

    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: FocusField?

    public init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            SampleTVTheme.Colors.canvas
                .ignoresSafeArea()

            VStack(spacing: 32) {
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle.on.rectangle")
                        .font(.system(size: 64, weight: .thin))
                        .foregroundStyle(.tint)

                    Text("SampleTV")
                        .font(SampleTVTheme.Typography.screenTitle)

                    Text("Sign in to sync your Watchlist, playback progress, and profile preferences.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 20) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)

                    SecureField("Password", text: $viewModel.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .password)
                }

                VStack(spacing: 16) {
                    Button {
                        Task { await viewModel.submit() }
                    } label: {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.state == .authenticating)
                    .focused($focusedField, equals: .signIn)
                    .accessibilityIdentifier("login.signInButton")

                    Button {
                        Task { await viewModel.continueAsDemo() }
                    } label: {
                        Text("Continue with Demo Account")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.state == .authenticating)
                    .focused($focusedField, equals: .demo)
                    .accessibilityIdentifier("login.demoButton")
                }

                if case .failed(let error) = viewModel.state {
                    Text(error.userMessage)
                        .font(.callout)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                if viewModel.state == .authenticating {
                    ProgressView()
                }
            }
            .padding(48)
            .frame(maxWidth: 620)
            .background(
                SampleTVTheme.Colors.surface.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(SampleTVTheme.Colors.glassBorder, lineWidth: 1)
            )
        }
        .onAppear {
            if focusedField == nil {
                focusedField = .demo
            }
        }
    }
}

#if DEBUG
#Preview {
    LoginView(viewModel: .preview)
}
#endif
