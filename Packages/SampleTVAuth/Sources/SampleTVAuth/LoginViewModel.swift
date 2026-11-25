import Observation
import SampleTVDomain

@MainActor
@Observable
public final class LoginViewModel {
    public enum State: Equatable {
        case idle
        case authenticating
        case authenticated(UserAccount)
        case failed(AuthError)
    }

    public var email = ""
    public var password = ""
    public private(set) var state: State = .idle

    private let signIn: SignIn
    private let signInDemo: SignInDemo
    private let onAuthenticated: @MainActor @Sendable (UserAccount) -> Void

    public init(
        signIn: SignIn,
        signInDemo: SignInDemo,
        onAuthenticated: @MainActor @Sendable @escaping (UserAccount) -> Void
    ) {
        self.signIn = signIn
        self.signInDemo = signInDemo
        self.onAuthenticated = onAuthenticated
    }

    public func submit() async {
        state = .authenticating
        do {
            let account = try await signIn(email: email, password: password)
            state = .authenticated(account)
            onAuthenticated(account)
        } catch is CancellationError {
            state = .idle
        } catch let authError as AuthError {
            state = .failed(authError)
        } catch {
            state = .failed(.invalidCredentials)
        }
    }

    public func continueAsDemo() async {
        state = .authenticating
        do {
            let account = try await signInDemo()
            state = .authenticated(account)
            onAuthenticated(account)
        } catch is CancellationError {
            state = .idle
        } catch let authError as AuthError {
            state = .failed(authError)
        } catch {
            state = .failed(.invalidCredentials)
        }
    }
}
