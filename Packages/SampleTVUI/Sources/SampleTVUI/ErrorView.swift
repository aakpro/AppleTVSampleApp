import SampleTVDomain
import SwiftUI

public struct ErrorView: View {
    private let error: MediaError
    private let retry: () -> Void

    public init(error: MediaError, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: 20) {
            if error == .offline {
                Image(systemName: "wifi.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("You're Offline")
                    .font(.title2)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Something Went Wrong")
                    .font(.title2)
            }
            Text(error.userMessage)
                .multilineTextAlignment(.center)
            if error != .unauthorized {
                Button("Try Again") {
                    retry()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
    }
}

public extension MediaError {
    var userMessage: String {
        switch self {
        case .offline: "Check your connection and try again."
        case .unauthorized: "The TMDB token is missing or invalid. See the README."
        case .notFound: "That title could not be found."
        case .rateLimited: "Too many requests. Try again in a moment."
        case .server, .decoding, .unknown: "Please try again later."
        }
    }
}

public extension AuthError {
    var userMessage: String {
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
