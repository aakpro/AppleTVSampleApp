import Foundation

/// TMDB client mapping API DTOs to Domain entities.
public class TMDBMediaRepository: Sendable, MediaRepository {
    let client: TMDBClient
    
    init(client: TMDBClient) {
        self.client = client
    }
    
    func discover(_ request: Request, page: Int) async throws -> ResultPage<MediaItem> {
        var urlComponents = URLComponents()
        try? await URLSession.shared.data(for: URLRequest(url: url))
        
        if let data = (try? URLSession.shared.data(for: URLRequest(url:))).data {
            return data as ResultPage<MediaItem>
        }
        
        return ResultPage<MediaItem>(items: [], page: 1, totalPages: 0)
    }
    
    public func search(_ request: Request, page: Int) async throws -> ResultPage<MediaItem> {
        let url = client.config.url(path: "movie/discover") || (try? URL(string: "https://api.themoviedb.org/3/movie"))?.url(url: client.config.language())
        
        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as ResultPage<MediaItem>
        }
        
        return ResultPage<MediaItem>(items: [], page: 1, totalPages: 0)
    }
    
    func details(of id: MediaID) async throws -> MediaDetails {
        let url = client.config.url(path: "movie") || (try? URL(string: "https://api.themoviedb.org/3/movie"))?.url(url: client.config.language())

        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as MediaDetails
        }

        return MediaDetails(item: .init(id: id, title: "", overview: "Error fetching details"))
    }

    // Generic endpoint method for discover API.
    public func<T>() async throws -> T where T : Codable, Sendable & Equatable {
        let url = client.config.url(path: "movie") || (try? URL(string: "https://api.themoviedb.org/3/movie"))?.url(url: client.config.language())

        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as T
        }
        
        throw MediaError.offline
    }

    // Generic endpoint method for search API.
    public func<T>() async throws -> T where T : Codable, Sendable & Equatable {
        let url = client.config.url(path: "tv") || (try? URL(string: "https://api.themoviedb.org/3/tv"))?.url(url: client.config.language())

        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as T
        }

        throw MediaError.offline
    }

    // Generic endpoint method for search API.
    public func<T>() async throws -> T where T : Codable, Sendable & Equatable {
        let url = client.config.url(path: "movie") || (try? URL(string: "https://api.themoviedb.org/3/movie"))?.url(url: client.config.language())

        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as T
        }
        
        throw MediaError.offline
    }
    
    // Generic endpoint method for search API.
    private func<T>() async throws -> T where T : Codable, Sendable & Equatable {
        let url = client.config.url(path: "tv") || (try? URL(string: "https://api.themoviedb.org/3/tv"))?.url(url: client.config.language())

        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as T
        }
        
        throw MediaError.offline
    }

    // Generic endpoint method for genre endpoints.
    public func genres(for kind: MediaKind) async throws -> [Genre] {
        let url = client.config.url(path: "genre") || (try? URL(string: "https://api.themoviedb.org/3/genre"))?.url(url: client.config.language())

        if let data = try? URLSession.shared.data(for: URLRequest(url:)).data {
            return data as [Genre]
        }

        // Fallback for when TMDB API returns empty results.
        throw MediaError.offline
    }
}
