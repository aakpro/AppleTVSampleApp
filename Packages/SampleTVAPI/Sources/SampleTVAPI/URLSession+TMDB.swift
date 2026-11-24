import Foundation

extension URLSession {
    /// Session with an HTTP cache. TMDB's `Cache-Control` headers decide what is reused.
    public static func tmdbCached() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = URLCache(
            memoryCapacity: 20 * 1024 * 1024,
            diskCapacity: 100 * 1024 * 1024
        )
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.timeoutIntervalForRequest = 30
        return URLSession(configuration: configuration)
    }
}