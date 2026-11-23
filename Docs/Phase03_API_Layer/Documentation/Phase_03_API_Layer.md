# Phase 3: API layer

| | |
|---|---|
| Branch | `feature/phase_03_api_layer` |
| Depends on | Phase 2 |
| Delivers | `SampleTVAPI` package: TMDB client with auth, retry and caching; DTO mapping; `TMDBMediaRepository` implementing `MediaRepository`; app wiring |

The HTTP contract (endpoints, parameters, errors) is in [API_SPECS.md](../../API_SPECS.md). This guide is the implementation.

## Deliverables

```
Packages/SampleTVAPI/
├── Package.swift                      depends on SampleTVDomain
├── Sources/SampleTVAPI/
│   ├── Transport.swift                HTTPTransport, TMDBConfiguration, RetryPolicy
│   ├── TMDBClient.swift               request building, status mapping, retry
│   ├── DTOs.swift                     TMDB JSON shapes -> Domain entities
│   ├── TMDBMediaRepository.swift      implements MediaRepository
│   └── URLSession+TMDB.swift          URLSession with an HTTP cache
└── Tests/SampleTVAPITests/
    ├── TMDBClientTests.swift          stubbed transport (status, retry, mapping, details)
    └── LiveTMDBTests.swift            opt-in, skipped unless a token is provided
```

## Design decisions

- **Auth** is the *Read Access Token* sent as `Authorization: Bearer …`. Never in the URL.
- **Transport seam**: `HTTPTransport.send(_:)` is the only thing tests replace. `URLSession` conforms via a
  tiny extension (a `data(for:)` wrapper would be ambiguous with `URLSession`'s own method).
- **Errors**: every failure becomes a `MediaError`; cancellation stays a `CancellationError` so SwiftUI tasks end quietly.
- **Retry**: up to 3 attempts for `429`, `5xx` and connectivity failures. Delay is `Retry-After` when the server
  sends it, otherwise 500 ms × 2^(attempt−1). Client errors (401, 404, decoding) are never retried.
- **No client-side rate limiter.** TMDB allows far more than this app issues; reacting to `429` is enough.
- **Caching** is the HTTP cache on the `URLSession` (20 MB memory, 100 MB disk). No custom disk store.
- **DTOs are internal** to the package and tolerant: all optional except `id`, so one missing field never fails a whole page.
- **Mapping details**: `vote_average == 0` becomes `nil`; only `movie`/`tv` results survive `search/multi`; the first four
  characters of the date become `releaseYear`.

## Steps

1. Branch, create the package, add it to the Xcode project (**Add Local…**) and link `SampleTVAPI` to the app target.
2. Add the code below and the tests.
3. Wire it into `AppContainer` (below).
4. Optional: run the live test once with your token.

## Code

**`Packages/SampleTVAPI/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVAPI",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVAPI", targets: ["SampleTVAPI"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain")
    ],
    targets: [
        .target(
            name: "SampleTVAPI",
            dependencies: [.product(name: "SampleTVDomain", package: "SampleTVDomain")]
        ),
        .testTarget(
            name: "SampleTVAPITests",
            dependencies: ["SampleTVAPI"]
        )
    ]
)
```

**`Packages/SampleTVAPI/Sources/SampleTVAPI/Transport.swift`**

```swift
import Foundation

/// Seam for tests: production uses `URLSession`, tests inject a stub.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}

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
```

**`Packages/SampleTVAPI/Sources/SampleTVAPI/TMDBClient.swift`**

```swift
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
```

**`Packages/SampleTVAPI/Sources/SampleTVAPI/DTOs.swift`**

```swift
import Foundation
import SampleTVDomain

struct PageDTO: Decodable, Sendable {
    let page: Int
    let results: [MediaDTO]
    let totalPages: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
    }
}

/// One DTO for both kinds: movies use `title`/`release_date`, TV uses `name`/`first_air_date`.
struct MediaDTO: Decodable, Sendable {
    let id: Int
    let mediaType: String?
    let title: String?
    let name: String?
    let overview: String?
    let releaseDate: String?
    let firstAirDate: String?
    let genreIDs: [Int]?
    let voteAverage: Double?
    let posterPath: String?
    let backdropPath: String?

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview
        case mediaType = "media_type"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
        case voteAverage = "vote_average"
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }

    /// Returns nil for results that are not playable media (e.g. `person` in `/search/multi`).
    func toDomain(defaultKind: MediaKind?) -> MediaItem? {
        let kind: MediaKind
        switch mediaType {
        case "movie": kind = .movie
        case "tv": kind = .tv
        case nil:
            guard let defaultKind else { return nil }
            kind = defaultKind
        default: return nil
        }
        let dateString = releaseDate ?? firstAirDate
        let year = dateString.flatMap { Int($0.prefix(4)) }
        return MediaItem(
            id: MediaID(kind: kind, value: id),
            title: title ?? name ?? "",
            overview: overview ?? "",
            releaseYear: year,
            genreIDs: genreIDs ?? [],
            rating: voteAverage.flatMap { $0 > 0 ? $0 : nil },
            posterPath: posterPath,
            backdropPath: backdropPath
        )
    }
}

struct GenreDTO: Decodable, Sendable {
    let id: Int
    let name: String
}

struct GenreListDTO: Decodable, Sendable {
    let genres: [GenreDTO]
}

struct RecommendationsDTO: Decodable, Sendable {
    let results: [MediaDTO]
}

struct DetailsDTO: Decodable, Sendable {
    let media: MediaDTO
    let genres: [GenreDTO]
    let runtime: Int?
    let numberOfSeasons: Int?
    let recommendations: RecommendationsDTO?

    enum CodingKeys: String, CodingKey {
        case genres, runtime, recommendations
        case numberOfSeasons = "number_of_seasons"
    }

    init(from decoder: Decoder) throws {
        // The detail payload is the list payload plus extras, so reuse MediaDTO for the shared part.
        media = try MediaDTO(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        genres = try container.decodeIfPresent([GenreDTO].self, forKey: .genres) ?? []
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons)
        recommendations = try container.decodeIfPresent(RecommendationsDTO.self, forKey: .recommendations)
    }

    func toDomain(kind: MediaKind) throws -> MediaDetails {
        guard var item = media.toDomain(defaultKind: kind) else { throw MediaError.decoding }
        // Detail responses carry `genres` objects instead of `genre_ids`.
        item = MediaItem(
            id: item.id, title: item.title, overview: item.overview, releaseYear: item.releaseYear,
            genreIDs: genres.map(\.id), rating: item.rating,
            posterPath: item.posterPath, backdropPath: item.backdropPath
        )
        return MediaDetails(
            item: item,
            genres: genres.map { Genre(id: $0.id, name: $0.name) },
            runtimeMinutes: runtime,
            seasonCount: numberOfSeasons,
            recommendations: (recommendations?.results ?? []).compactMap { $0.toDomain(defaultKind: kind) }
        )
    }
}
```

**`Packages/SampleTVAPI/Sources/SampleTVAPI/TMDBMediaRepository.swift`**

```swift
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
```

**`Packages/SampleTVAPI/Sources/SampleTVAPI/URLSession+TMDB.swift`**

```swift
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
```

## App wiring

`AppContainer` gains the repository. The app target is the **only** place that imports `SampleTVAPI`.

```swift
import Foundation
import SampleTVAPI
import SampleTVDomain

@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    let repository: any MediaRepository

    init(configuration: AppConfiguration, repository: any MediaRepository) {
        self.configuration = configuration
        self.repository = repository
    }

    static func live() -> AppContainer {
        let configuration = AppConfiguration()
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: configuration.tmdbToken),
            transport: URLSession.tmdbCached()
        )
        return AppContainer(configuration: configuration, repository: TMDBMediaRepository(client: client))
    }
}
```

## Tests

**`Packages/SampleTVAPI/Tests/SampleTVAPITests/TMDBClientTests.swift`**

```swift
import Foundation
import Testing
import SampleTVDomain
@testable import SampleTVAPI

struct StubResponse: Sendable {
    var status = 200
    var body = "{}"
    var headers: [String: String] = [:]
}

actor StubTransport: HTTPTransport {
    private var responses: [StubResponse]
    private(set) var requests: [URLRequest] = []

    init(_ responses: [StubResponse]) {
        self.responses = responses
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let next = responses.removeFirst()
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url, statusCode: next.status, httpVersion: nil, headerFields: next.headers
              )
        else { throw MediaError.unknown }
        return (Data(next.body.utf8), response)
    }
}

private let tvPage = """
{"page":1,"total_pages":3,"results":[
 {"id":1396,"name":"Breaking Bad","first_air_date":"2008-01-20","genre_ids":[18],"vote_average":8.9,"poster_path":"/p.jpg"}
]}
"""

struct TMDBClientTests {
    private func repository(_ stub: StubTransport) -> TMDBMediaRepository {
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: "token"),
            transport: stub,
            retryPolicy: RetryPolicy(maxAttempts: 3, baseDelay: .milliseconds(1))
        )
        return TMDBMediaRepository(client: client)
    }

    @Test func discoverMapsTVResultsAndSendsBearerToken() async throws {
        let stub = StubTransport([StubResponse(body: tvPage)])
        let filter = MediaFilter(kind: .tv, genreIDs: [18])
        let page = try await repository(stub).discover(filter, page: 1)
        #expect(page.items.first?.title == "Breaking Bad")
        #expect(page.items.first?.releaseYear == 2008)
        #expect(page.items.first?.id == MediaID(kind: .tv, value: 1396))
        #expect(page.hasNextPage)
        let request = try #require(await stub.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(request.url?.query?.contains("with_genres=18") == true)
    }

    @Test func retriesOn429ThenSucceeds() async throws {
        let stub = StubTransport([
            StubResponse(status: 429, headers: ["Retry-After": "0"]),
            StubResponse(body: tvPage)
        ])
        let page = try await repository(stub).discover(MediaFilter(), page: 1)
        #expect(page.items.count == 1)
        #expect(await stub.requests.count == 2)
    }

    @Test func mapsStatusCodesWithoutRetryingClientErrors() async throws {
        let stub = StubTransport([StubResponse(status: 404)])
        await #expect(throws: MediaError.notFound) {
            _ = try await repository(stub).discover(MediaFilter(), page: 1)
        }
        #expect(await stub.requests.count == 1)
    }

    @Test func searchMultiDropsPeople() async throws {
        let body = """
        {"page":1,"total_pages":1,"results":[
         {"id":1,"media_type":"person","name":"Someone"},
         {"id":2,"media_type":"movie","title":"Heat","release_date":"1995-12-15"}]}
        """
        let stub = StubTransport([StubResponse(body: body)])
        let page = try await repository(stub).search(try #require(SearchQuery("heat")), page: 1)
        #expect(page.items.map(\.title) == ["Heat"])
    }
}

struct DetailsMappingTests {
    @Test func detailsDecodeGenresRuntimeAndRecommendations() async throws {
        let body = """
        {"id":603,"title":"The Matrix","overview":"x","release_date":"1999-03-30","vote_average":8.2,
         "genres":[{"id":28,"name":"Action"},{"id":878,"name":"Science Fiction"}],"runtime":136,
         "recommendations":{"results":[{"id":604,"title":"Reloaded","release_date":"2003-05-15"}]}}
        """
        let stub = StubTransport([StubResponse(body: body)])
        let client = TMDBClient(configuration: TMDBConfiguration(readAccessToken: "t"), transport: stub)
        let id = MediaID(kind: .movie, value: 603)
        let details = try await TMDBMediaRepository(client: client).details(of: id)
        #expect(details.item.title == "The Matrix")
        #expect(details.genres.map(\.name) == ["Action", "Science Fiction"])
        #expect(details.runtimeMinutes == 136)
        #expect(details.recommendations.map(\.title) == ["Reloaded"])
        let request = try #require(await stub.requests.first)
        #expect(request.url?.path.hasSuffix("/movie/603") == true)
    }
}
```

Add cases for: `401` → `.unauthorized`; `503` retried then `.server(503)`; offline transport error →
`.offline` after 3 attempts; undecodable body → `.decoding`; discover with years and rating adds the
`first_air_date.*`/`vote_average.gte`/`vote_count.gte` items; movie filters use `primary_release_date.*`;
`genres(for:)` mapping; `Retry-After` wins over backoff. Target ≥ 85% coverage.

### Live test (opt-in)

**`Packages/SampleTVAPI/Tests/SampleTVAPITests/LiveTMDBTests.swift`**

```swift
import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVAPI

/// Opt-in: runs only when TMDB_READ_ACCESS_TOKEN is set. Never part of CI.
struct LiveTMDBTests {
    private static let token = ProcessInfo.processInfo.environment["TMDB_READ_ACCESS_TOKEN"]

    @Test(.enabled(if: token != nil))
    func discoverReturnsResults() async throws {
        let configuration = TMDBConfiguration(readAccessToken: Self.token ?? "")
        let repository = TMDBMediaRepository(client: TMDBClient(configuration: configuration))
        let page = try await repository.discover(MediaFilter(), page: 1)
        #expect(!page.items.isEmpty)
    }
}
```

Skipped by default. To run it, pass the token through the `TEST_RUNNER_` prefix (Xcode forwards those variables, minus the
prefix, to the test process):

```bash
TEST_RUNNER_TMDB_READ_ACCESS_TOKEN="$YOUR_TOKEN" \
  xcodebuild test -scheme SampleTVAPI -destination "id=$UDID" -only-testing:SampleTVAPITests/LiveTMDBTests
```

With a bad token this fails with `unauthorized`, which also confirms TMDB's `401` is mapped correctly.

## Verify

```bash
cd Packages/SampleTVAPI && xcodebuild test -scheme SampleTVAPI -destination "id=$UDID" -enableCodeCoverage YES
cd ../.. && xcodebuild build -scheme SampleTV -destination "id=$UDID"
swiftlint lint --quiet | grep -c "error:"                      # 0
grep -rn "import SampleTVAPI" Packages | grep -v "Packages/SampleTVAPI/"   # must print nothing
```

## Definition of done

- [ ] `SampleTVAPI` tests pass without network access; coverage ≥ 85%.
- [ ] Only the app target imports `SampleTVAPI` (the SwiftLint boundary rule is green).
- [ ] The app builds with `AppContainer.live()` and the repository wired.
- [ ] Live test passes once locally with a real token (not in CI).
- [ ] CI green; status table and `CHANGELOG.md` updated.

## Next

[Phase 4](../../Phase04_Movie_Discovery/Documentation/Phase_04_Movie_Discovery.md): UI components and the discovery screen.
