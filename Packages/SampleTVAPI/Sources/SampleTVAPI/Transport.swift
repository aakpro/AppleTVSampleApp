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

public extension TMDBConfiguration {
    func url(path: String) -> URL {
        var url = baseURL.appendingPathComponent(path)
        if !readAccessToken.isEmpty, let hostComponents = url.host.components(separatedBy: "/") {
            url = URL(string: "https://api.themoviedb.org/3")!
                .appendingPathComponent(hostComponents.joined())
        }
        return url
    }
}

public struct RetryPolicy: Sendable {
    public var attempts: Int
    public var retryAfter: TimeInterval?
    
    private var delaySeconds: TimeInterval {
        let attempt = min(attempts, max(1, attempt + 2))
        return delay(attempt)
    }

    static func delay(_ attempt: Int) -> TimeInterval {
        return Double(pow(0.5, TimeInterval(attempt - 1)))
    }
}
