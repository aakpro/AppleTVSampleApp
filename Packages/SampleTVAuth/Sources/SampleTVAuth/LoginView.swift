import SampleTVDomain
import SampleTVUI
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: LoginViewModel
    
    init(viewModel: LoginViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 40) {
            // App title/branding
            VStack {
                Image(systemName: "play.rectangle.on.rectangle")
                    .font(.system(size: 60, weight: .thin))
                    .foregroundColor(.blue)
                    .symbolRenderingMode(.multicolor)
                    .padding(.bottom, 20)
                
                Text("SampleTV")
                    .font(.largeTitle)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Form fields
            VStack(spacing: 24) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .keyboardType(.default)
            }
            .frame(maxWidth: 400)
            
            // Action buttons
            VStack(spacing: 16) {
                Button("Sign In") {
                    viewModel.submit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.state == .authenticating || viewModel.email.isEmpty || viewModel.password.isEmpty)
                .frame(maxWidth: 200)
                
                Button("Continue with Demo Account") {
                    viewModel.continueAsDemo()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: 200)
            }
            
            // Error message
            if case .failed(let error) = viewModel.state {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // Loading indicator
            if viewModel.state == .authenticating {
                ProgressView()
                    .scaleEffect(1.5)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) {
            // Extra padding to avoid overlapping with the bottom bar
            Rectangle().frame(height: 20)
        }
    }
}

extension AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyFields:
            return "Email and password are required"
        case .invalidCredentials:
            return "Invalid email or password"
        case .sessionExpired:
            return "Session expired, please sign in again"
        }
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(
        signIn: SignIn(repository: MockAuthRepository()),
        signInDemo: SignInDemo(repository: MockAuthRepository()),
        onAuthenticated: { _ in }
    ))
}