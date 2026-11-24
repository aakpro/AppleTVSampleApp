import SampleTVDomain
import SwiftUI

struct ErrorView: View {
    let error: MediaError
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if error == .offline {
                Image(systemName: "wifi.slash")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("You're Offline")
                    .font(.title2)
                Text("Check your connection and try again.")
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Something Went Wrong")
                    .font(.title2)
                Text(message)
                    .multilineTextAlignment(.center)
            }
            if error != .unauthorized {
                Button("Try Again") {
                    retry()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
    }

    private var message: String {
        switch error {
        case .offline: "Check your connection and try again."
        case .unauthorized: "The TMDB token is missing or invalid. See the README."
        case .notFound: "That title could not be found."
        case .rateLimited: "Too many requests. Try again in a moment."
        case .server, .decoding, .unknown: "Please try again later."
        }
    }
}