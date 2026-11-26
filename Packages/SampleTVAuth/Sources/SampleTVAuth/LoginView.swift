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
                Text(error.userMessage)
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

#if DEBUG
#Preview {
    LoginView(viewModel: .preview)
}
#endif
