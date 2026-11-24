import Foundation
import SampleTVDomain

public struct TMDBMediaRepository: MediaRepository {
    private let client: TMDBClient

    public init(client: TMDBClient) {
        self.client = client
    }

    public func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> {
        var query = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sort_by", value: Self.sortValue(for: filter)),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        if !filter.genreIDs.isEmpty {
            // Comma means AND in TMDB; use "|" to mean OR.
            let ids = filter.genreIDs.sorted().map(String.init).joined(separator: ",")
            query.append(URLQueryItem(name: "with_genres", value: ids))
        }
        if let years = filter.years {
            let dateKey = filter.kind == .movie ? "primary_release_date" : "first_air_date"
            query.append(URLQueryItem(name: "\(dateKey).gte", value: "\(years.lowerBound)-01-01"))
            query.append(URLQueryItem(name: "\(dateKey).lte", value: "\(years.upperBound)-12-31"))
        }
        if let rating = filter.minimumRating {
            query.append(URLQueryItem(name: "vote_average.gte", value: String(rating)))
            // Avoid 10/10 results backed by a single vote.
            query.append(URLQueryItem(name: "vote_count.gte", value: "50"))
        }
        let dto: PageDTO = try await client.get("discover/\(filter.kind.rawValue)", query: query)
        return Self.map(dto, defaultKind: filter.kind)
    }

    public func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        let endpoint = query.kind.map { "search/\($0.rawValue)" } ?? "search/multi"
        let items = [
            URLQueryItem(name: "query", value: query.text),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        let dto: PageDTO = try await client.get(endpoint, query: items)
        return Self.map(dto, defaultKind: query.kind)
    }

    public func details(of id: MediaID) async throws -> MediaDetails {
        let dto: DetailsDTO = try await client.get(
            "\(id.kind.rawValue)/\(id.value)",
            query: [URLQueryItem(name: "append_to_response", value: "recommendations")]
        )
        return try dto.toDomain(kind: id.kind)
    }

    public func genres(for kind: MediaKind) async throws -> [Genre] {
        let dto: GenreListDTO = try await client.get("genre/\(kind.rawValue)/list")
        return dto.genres.map { Genre(id: $0.id, name: $0.name) }
    }

    private static func sortValue(for filter: MediaFilter) -> String {
        switch (filter.sort, filter.kind) {
        case (.popularity, _): "popularity.desc"
        case (.rating, _): "vote_average.desc"
        case (.newest, .movie): "primary_release_date.desc"
        case (.newest, .tv): "first_air_date.desc"
        }
    }

    private static func map(_ dto: PageDTO, defaultKind: MediaKind?) -> ResultPage<MediaItem> {
        ResultPage(
            items: dto.results.compactMap { $0.toDomain(defaultKind: defaultKind) },
            page: dto.page,
            totalPages: dto.totalPages
        )
    }
}