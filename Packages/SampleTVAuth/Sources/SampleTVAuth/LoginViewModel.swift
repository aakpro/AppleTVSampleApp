import Foundation
import SampleTVDomain
import SwiftUI

@MainActor
public final class LoginViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    
    public enum State {
        case idle
        case authenticating
        case authenticated(UserAccount)
        case failed(AuthError)
    }
    
    @Published public var state: State = .idle
    
    private let signIn: SignIn
    private let signInDemo: SignInDemo
    private let onAuthenticated: (UserAccount) -> Void
    
    public init(
        signIn: SignIn,
        signInDemo: SignInDemo,
        onAuthenticated: @MainActor @Sendable @escaping (UserAccount) -> Void
    ) {
        self.signIn = signIn
        self.signInDemo = signInDemo
        self.onAuthenticated = onAuthenticated
    }
    
    public func submit() {
        Task {
            do {
                state = .authenticating
                let account = try await signIn(email: email, password: password)
                state = .authenticated(account)
                onAuthenticated(account)
            } catch {
                if let authError = error as? AuthError {
                    state = .failed(authError)
                } else {
                    // Handle other errors as invalid credentials for simplicity
                    state = .failed(.invalidCredentials)
                }
            }
        }
    }
    
    public func continueAsDemo() {
        Task {
            do {
                state = .authenticating
                let account = try await signInDemo()
                state = .authenticated(account)
                onAuthenticated(account)
            } catch {
                if let authError = error as? AuthError {
                    state = .failed(authError)
                } else {
                    // Handle other errors as invalid credentials for simplicity
                    state = .failed(.invalidCredentials)
                }
            }
        }
    }
}