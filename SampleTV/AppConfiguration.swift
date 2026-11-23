import Foundation

struct AppConfiguration: Sendable {
    let tmdbToken: String

    init(tmdbToken: String) {
        self.tmdbToken = tmdbToken
    }

    init(bundle: Bundle = .main) {
        self.init(tmdbToken: bundle.object(forInfoDictionaryKey: "TMDBReadAccessToken") as? String ?? "")
    }

    /// False when Secrets.xcconfig is missing (empty) or still holds the example placeholder.
    var hasToken: Bool {
        !tmdbToken.isEmpty && tmdbToken != "paste_your_token_here"
    }
}
