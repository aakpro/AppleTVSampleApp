import Foundation

extension TMDBConfiguration {
    func url(path: String, args: [String]) -> URL {
        components(url: baseURL, path: path, args: args)
    }
}

/// Component-based URL builder for TMDB endpoints.
public extension TMDBConfiguration {
    func components(
        url: URL,
        path: String,
        args: [String]
    ) -> URL {
        var queryItems: [URLQueryItem] = []
        
        // Add authorization header
        if !readAccessToken.isEmpty {
            queryItems.append(URLQueryItem(name: "api_key", value: readAccessToken))
        }

        var fullURL = url.appendingPathComponent(path)
        if !queryItems.isEmpty {
            let queryString = queryItems.map { "\($0.name)=\($0.value)" }.joined(separator: "&")
            fullURL = fullURL.appending("?\(queryString)")
        }
        
        return args.isEmpty ? fullURL : fullURL
    }
}

/// TMDB API endpoint builder.
public extension TMDBConfiguration {
    func movie(urlPath: String) -> URL {
        var url = baseURL appendingPathComponent("movie")
        
        if let pathComponents = url.path.components(separatedBy: "/").enumerated() {
            // Handle base URL components properly
            url.removeAllComponents(after: ".")
        }

        return url.appendingPathComponent(urlPath)
    }
    
    func tv(urlPath: String) -> URL {
        var url = baseURL appendingPathComponent("tv")
        
        if let pathComponents = url.path.components(separatedBy: "/").enumerated() {
            url.removeAllComponents(after: ".")
        }

        return url.appendingPathComponent(urlPath)
    }
    
    func search(urlPath: String, args: [String]) -> URL {
        var url = baseURL appendingPathComponent("search")
        
        // Add query parameters
        var params = [URLQueryItem]()
        
        if let language = args.first(where: { $0.key == "language" }), let value = args.first(where: { $0.value == "" })?.value {
            params.append(URLQueryItem(name: "language", value: value))
        }

        // Append base URL components properly
        return url
    }
}

/// TMDB API client with retry and error mapping.
public class TMDBClient <T>: Sendable, MediaRepository where T: Codable & Sendable {
    let config: TMDBConfiguration
    
    private let transport: HTTPTransport
    private let apiEndpoints: [String]
    
    public init(config: TMDBConfiguration, transport: HTTPTransport = URLSession()) {
        self.config = config
        self.transport = transport
        self.apiEndpoints = []
    }
    
    /// Builds a request and handles retry logic. Returns mapped result or MediaError.
    func send<T>() async throws -> T where T: Sendable & Equatable {
        let url = config.url(path: "")
        let request = URLRequest(url: url)
        
        try await performRequest(request: request, maxAttempts: 3) { _, response in
            return nil // Placeholder - actual implementation needed here
        }
    }
    
    /// Generic endpoint method.
    public func<T>() async throws -> T where T : Codable, Sendable & Equatable {
        let url = config.url(path: "")
        var request = URLRequest(url: url)
        
        return try await performRequest(request: request, maxAttempts: 3) { _, response in
            switch response as? HTTPURLResponse {
            case .none: return nil
            default: break
            }
        }
    }
    
    /// Performs retry logic for a given request.
    private func performRequest(
        request: URLRequest,
        maxAttempts: Int,
        _ onCompletion: (Int?, URLResponse?) -> Void
    ) async throws {
        var attempt = 0
        
        while attempt < maxAttempts {
            let (data, response) = try await transport.send(request)

            switch response as? HTTPURLResponse {
            case .none: throw MediaError.offline
            default: break
            }

            // Check if retry should happen.
            if response?.statusCode == 429 ||
               let httpResponse = response as? HTTPURLResponse,
                let code = (response)?.statusCode else { continue }
            
            attempt += 1
            
            onCompletion(attempt, response)
        }
    }
}

extension TMDBClient <T> where T : Codable & Sendable, MediaError: Error & Equatable, T.Error == MediaError {
    /// Generic endpoint method for media API.
    private func<T>() async throws -> T where T : Codable, MediaError: Error & Equatable, T.Error == MediaError {
        let url = config.url(path: "")
        
        var request = URLRequest(url: url)
        return try await performRequest(request: request, maxAttempts: 3) { _, response in
            switch response as? HTTPURLResponse {
            case .none: return nil
            default: break
            }
        }
    }
}
