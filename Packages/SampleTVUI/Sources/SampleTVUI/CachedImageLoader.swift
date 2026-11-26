import Foundation
import SwiftUI

/// Actor-based image loader that uses a shared URLSession with URLCache for efficient caching
actor CachedImageLoader {
    /// Shared URLSession with custom configuration for image loading
    private let urlSession: URLSession
    
    /// Initializes the CachedImageLoader with a configured URLSession
    init() {
        // Configure URLCache with generous memory and disk capacity for images
        let urlCache = URLCache(
            memoryCapacity: 50 * 1024 * 1024, // 50 MB memory cache
            diskCapacity: 200 * 1024 * 1024   // 200 MB disk cache
        )
        
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 5
        config.timeoutInterval = 30
        config.timeoutIntervalForResource = 60
        config.httpShouldSetCookies = false
        
        self.urlSession = URLSession(configuration: config, delegate: nil, delegateQueue: nil)
        // Set the URLCache on the configuration  
        self.urlSession.configuration.urlCache = urlCache
        
        self.urlSession.setTaskDidReceiveResponseBlock { _, _, response in
            // Use the default policy to allow caching of image responses
            return .allow
        }
    }
    
    /// Loads an image from a URL with cache handling
    func loadImage(from url: URL) async throws -> Image {
        // Create the data task and wait for completion 
        let (data, response) = try await urlSession.data(for: URLRequest(url: url))
        
        // Validate response and create image from data
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode),
              let image = Image(data: data)
        else {
            throw URLError(.badServerResponse)
        }
        
        return image
    }
    
    /// Checks if an image is cached for a given URL
    func isImageCached(for url: URL) -> Bool {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        let cachedResponse = urlSession.configuration.urlCache?.cachedResponse(for: request)
        return cachedResponse != nil
    }
}