import Foundation

struct AppConfiguration: Sendable {
    let tmdbToken: String

    nonisolated init(tmdbToken: String) {
        self.tmdbToken = tmdbToken
    }

    nonisolated init(bundle: Bundle = .main) {
        self.init(tmdbToken: bundle.object(forInfoDictionaryKey: "TMDBReadAccessToken") as? String ?? "")
    }

    /// False when Secrets.xcconfig is missing (empty) or still holds the example placeholder.
    nonisolated var hasToken: Bool {
        !tmdbToken.isEmpty && tmdbToken != "paste_your_token_here"
    }
}
