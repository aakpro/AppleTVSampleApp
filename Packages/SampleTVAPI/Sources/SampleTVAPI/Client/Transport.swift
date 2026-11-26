import Foundation

/// Seam for tests: production uses URLSession, tests inject a stub.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

/// TMDB client configuration loaded from Config/Secrets.xcconfig.
public struct TMDBConfiguration: Sendable {
    public var baseURL: URL
    public var readAccessToken: String
    public var language: String

    public init(
        baseURL: URL = URL(string: "https://api.themoviedb.org/3")!,
        readAccessToken: String,
        language: String = "en-US"
    ) {
        self.baseURL = baseURL
        self.readAccessToken = readAccessToken
        self.language = language
    }
}

public struct RetryPolicy: Sendable {
    public var maxAttempts: Int
    public var baseDelay: Duration

    public init(maxAttempts: Int = 3, baseDelay: Duration = .milliseconds(500)) {
        self.maxAttempts = maxAttempts
        self.baseDelay = baseDelay
    }

    /// `attempt` is 1-based. A server-provided `Retry-After` always wins.
    public func delay(afterAttempt attempt: Int, retryAfter: TimeInterval?) -> Duration {
        if let retryAfter { return .seconds(retryAfter) }
        return baseDelay * Int(pow(2.0, Double(attempt - 1)))
    }
}
