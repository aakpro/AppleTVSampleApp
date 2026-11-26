import Foundation
import SwiftUI
import UIKit

/// Actor-based image loader backed by a shared configured `URLSession` and `URLCache`
/// that deduplicates concurrent in-flight downloads for the same URL.
public actor CachedImageLoader {
    public static let shared = CachedImageLoader()

    private let urlSession: URLSession
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    public init(urlSession: URLSession? = nil) {
        if let urlSession {
            self.urlSession = urlSession
        } else {
            let cache = URLCache(
                memoryCapacity: 64 * 1024 * 1024,
                diskCapacity: 256 * 1024 * 1024,
                directory: nil
            )
            let config = URLSessionConfiguration.default
            config.urlCache = cache
            config.requestCachePolicy = .returnCacheDataElseLoad
            config.httpMaximumConnectionsPerHost = 6
            config.timeoutIntervalForRequest = 30
            config.timeoutIntervalForResource = 60
            self.urlSession = URLSession(configuration: config)
        }
    }

    public func loadUIImage(from url: URL) async throws -> UIImage {
        if let existingTask = inFlight[url] {
            return try await existingTask.value
        }

        let session = self.urlSession
        let task = Task<UIImage, Error> {
            var request = URLRequest(url: url)
            request.cachePolicy = .returnCacheDataElseLoad
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let image = UIImage(data: data)
            else {
                throw URLError(.badServerResponse)
            }
            return image
        }

        inFlight[url] = task
        do {
            let image = try await task.value
            inFlight[url] = nil
            return image
        } catch {
            inFlight[url] = nil
            throw error
        }
    }

    public func loadImage(from url: URL) async throws -> Image {
        Image(uiImage: try await loadUIImage(from: url))
    }

    public func isImageCached(for url: URL) -> Bool {
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        return urlSession.configuration.urlCache?.cachedResponse(for: request) != nil
    }
}
