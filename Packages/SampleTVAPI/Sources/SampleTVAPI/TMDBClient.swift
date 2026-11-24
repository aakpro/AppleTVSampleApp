import Foundation
import SampleTVDomain

public struct TMDBClient: Sendable {
    private let configuration: TMDBConfiguration
    private let transport: any HTTPTransport
    private let retryPolicy: RetryPolicy

    public init(
        configuration: TMDBConfiguration,
        transport: any HTTPTransport = URLSession.shared,
        retryPolicy: RetryPolicy = RetryPolicy()
    ) {
        self.configuration = configuration
        self.transport = transport
        self.retryPolicy = retryPolicy
    }

    public func get<Response: Decodable & Sendable>(
        _ path: String,
        query: [URLQueryItem] = []
    ) async throws -> Response {
        let request = try makeRequest(path: path, query: query)
        var attempt = 1
        while true {
            do {
                let data = try await perform(request)
                do {
                    return try JSONDecoder().decode(Response.self, from: data)
                } catch {
                    throw MediaError.decoding
                }
            } catch let error as MediaError where isRetryable(error) && attempt < retryPolicy.maxAttempts {
                let retryAfter: TimeInterval?
                if case .rateLimited(let seconds) = error { retryAfter = seconds } else { retryAfter = nil }
                try await Task.sleep(for: retryPolicy.delay(afterAttempt: attempt, retryAfter: retryAfter))
                attempt += 1
            }
        }
    }

    private func makeRequest(path: String, query: [URLQueryItem]) throws -> URLRequest {
        guard var components = URLComponents(
            url: configuration.baseURL.appending(path: path),
            resolvingAgainstBaseURL: false
        ) else { throw MediaError.unknown }
        components.queryItems = [URLQueryItem(name: "language", value: configuration.language)] + query
        guard let url = components.url else { throw MediaError.unknown }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(configuration.readAccessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 30
        return request
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.send(request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as URLError where error.code == .notConnectedToInternet {
            throw MediaError.offline
        } catch {
            throw error is CancellationError ? error : MediaError.offline
        }
        guard let http = response as? HTTPURLResponse else { throw MediaError.unknown }
        switch http.statusCode {
        case 200..<300: return data
        case 401: throw MediaError.unauthorized
        case 404: throw MediaError.notFound
        case 429:
            let seconds = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw MediaError.rateLimited(retryAfter: seconds)
        default: throw MediaError.server(statusCode: http.statusCode)
        }
    }

    private func isRetryable(_ error: MediaError) -> Bool {
        switch error {
        case .rateLimited, .offline: true
        case .server(let code): code >= 500
        default: false
        }
    }
}