# Phase 2: Domain layer

| | |
|---|---|
| Branch | `feature/phase_02_domain_layer` |
| Depends on | Phase 1 |
| Delivers | `SampleTVDomain` package: entities, query types, the `MediaRepository` port, use cases, `MediaError` |

> Earlier drafts put the API layer before the Domain. That cannot work cleanly: the API layer implements a
> protocol the Domain defines and returns Domain entities. The order is now Domain (this phase), then API (Phase 3).

The Domain imports **Foundation only**. No SwiftUI, no networking, no TMDB field names.

## Deliverables

```
Packages/SampleTVDomain/
├── Package.swift
├── Sources/SampleTVDomain/
│   ├── Entities.swift        MediaKind, MediaID, Genre, MediaItem, MediaDetails, ResultPage
│   ├── Query.swift           MediaSort, MediaFilter (+ matches), SearchQuery
│   ├── Repository.swift      MediaError, MediaRepository (the port)
│   └── UseCases.swift        DiscoverMedia, SearchMedia, GetMediaDetails
└── Tests/SampleTVDomainTests/
    ├── SearchMediaTests.swift
    └── MediaFilterTests.swift
```

## Steps

1. `git switch -c feature/phase_02_domain_layer`, create the folder structure above.
2. Add the package to the app: Xcode → File → Add Package Dependencies → **Add Local…** → `Packages/SampleTVDomain`,
   and link the `SampleTVDomain` library to the **SampleTV** target. (Packages that depend on each other
   resolve transitively; the app only needs the ones it imports directly.)
3. Add the code below. Every file here compiled, and its tests passed, on the tvOS simulator in Swift 6 mode.
4. Confirm the Domain contains no forbidden imports (the SwiftLint rule `domain_is_framework_free` does this in CI).

### Design notes

- **One `MediaItem` for movies and shows**, discriminated by `MediaID.kind`. The UI treats them identically, so
  parallel `Movie`/`TVShow` types would only duplicate code.
- **`MediaID` is `(kind, value)`**: TMDB movie 603 and TV show 603 are different titles.
- **Entities have no `Codable` TMDB mapping.** `Codable` is there so view models can persist or cache them later;
  the snake_case TMDB shapes live in the API package as DTOs.
- **Use cases carry rules, not plumbing.** `SearchMedia` refuses to hit the repository for text shorter than
  `SearchQuery.minimumLength`. That rule is business logic and is unit-tested here.
- **`MediaFilter.matches(_:)` is pure.** TMDB's search endpoints cannot filter by genre, rating or year range,
  so Phase 5 applies this function to search results on the client.
- **Errors**: `MediaError` is the only error type the rest of the app sees. `CancellationError` is deliberately not
  wrapped.

## Code

### Package manifest

**`Packages/SampleTVDomain/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVDomain",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVDomain", targets: ["SampleTVDomain"])
    ],
    targets: [
        .target(name: "SampleTVDomain"),
        .testTarget(
            name: "SampleTVDomainTests",
            dependencies: ["SampleTVDomain"]
        )
    ]
)
```

`platforms: [.tvOS(.v17)]` is the minimum for `@Observable` in the feature packages. The app itself targets a
newer tvOS; packages only need to be no *higher* than the app.

### Entities

**`Packages/SampleTVDomain/Sources/SampleTVDomain/Entities.swift`**

```swift
import Foundation

public enum MediaKind: String, Codable, Sendable, CaseIterable {
    case movie
    case tv
}

/// TMDB movie and TV ids live in separate namespaces, so an id alone is not unique.
public struct MediaID: Codable, Hashable, Sendable {
    public let kind: MediaKind
    public let value: Int

    public init(kind: MediaKind, value: Int) {
        self.kind = kind
        self.value = value
    }
}

public struct Genre: Codable, Hashable, Sendable, Identifiable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct MediaItem: Codable, Hashable, Sendable, Identifiable {
    public let id: MediaID
    public let title: String
    public let overview: String
    public let releaseYear: Int?
    public let genreIDs: [Int]
    public let rating: Double?
    public let posterPath: String?
    public let backdropPath: String?

    public init(
        id: MediaID,
        title: String,
        overview: String = "",
        releaseYear: Int? = nil,
        genreIDs: [Int] = [],
        rating: Double? = nil,
        posterPath: String? = nil,
        backdropPath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.releaseYear = releaseYear
        self.genreIDs = genreIDs
        self.rating = rating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
    }
}

public struct MediaDetails: Codable, Hashable, Sendable {
    public let item: MediaItem
    public let genres: [Genre]
    public let runtimeMinutes: Int?
    public let seasonCount: Int?
    public let recommendations: [MediaItem]

    public init(
        item: MediaItem,
        genres: [Genre] = [],
        runtimeMinutes: Int? = nil,
        seasonCount: Int? = nil,
        recommendations: [MediaItem] = []
    ) {
        self.item = item
        self.genres = genres
        self.runtimeMinutes = runtimeMinutes
        self.seasonCount = seasonCount
        self.recommendations = recommendations
    }
}

public struct ResultPage<Element: Sendable & Equatable>: Sendable, Equatable {
    public let items: [Element]
    public let page: Int
    public let totalPages: Int

    public var hasNextPage: Bool { page < totalPages }

    public init(items: [Element], page: Int, totalPages: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
    }

    public static var empty: ResultPage { .init(items: [], page: 1, totalPages: 1) }
}
```

### Queries and filtering

**`Packages/SampleTVDomain/Sources/SampleTVDomain/Query.swift`**

```swift
import Foundation

public enum MediaSort: String, Codable, Sendable, CaseIterable {
    case popularity
    case rating
    case newest
}

public struct MediaFilter: Equatable, Sendable {
    public var kind: MediaKind
    public var genreIDs: Set<Int>
    public var years: ClosedRange<Int>?
    public var minimumRating: Double?
    public var sort: MediaSort

    public init(
        kind: MediaKind = .tv,
        genreIDs: Set<Int> = [],
        years: ClosedRange<Int>? = nil,
        minimumRating: Double? = nil,
        sort: MediaSort = .popularity
    ) {
        self.kind = kind
        self.genreIDs = genreIDs
        self.years = years
        self.minimumRating = minimumRating
        self.sort = sort
    }
}

/// A validated search request. Construction fails for input that is too short to search.
public struct SearchQuery: Equatable, Sendable {
    public static let minimumLength = 2

    public let text: String
    public let kind: MediaKind?

    public init?(_ rawText: String, kind: MediaKind? = nil) {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= Self.minimumLength else { return nil }
        self.text = trimmed
        self.kind = kind
    }
}

extension MediaFilter {
    /// Applies the filter on the client. Used for search results, because TMDB's search
    /// endpoints cannot filter by genre, year or rating. Items with unknown values are excluded
    /// only when the corresponding criterion is set.
    public func matches(_ item: MediaItem) -> Bool {
        if item.id.kind != kind { return false }
        if !genreIDs.isEmpty, genreIDs.isDisjoint(with: item.genreIDs) { return false }
        if let years {
            guard let year = item.releaseYear, years.contains(year) else { return false }
        }
        if let minimumRating {
            guard let rating = item.rating, rating >= minimumRating else { return false }
        }
        return true
    }
}
```

### The port and its error type

**`Packages/SampleTVDomain/Sources/SampleTVDomain/Repository.swift`**

```swift
import Foundation

public enum MediaError: Error, Equatable, Sendable {
    case offline
    case unauthorized
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case server(statusCode: Int)
    case decoding
    case unknown
}

/// Port implemented by the data layer (`SampleTVAPI`). The domain only knows this protocol.
public protocol MediaRepository: Sendable {
    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem>
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem>
    func details(of id: MediaID) async throws -> MediaDetails
    func genres(for kind: MediaKind) async throws -> [Genre]
}
```

### Use cases

**`Packages/SampleTVDomain/Sources/SampleTVDomain/UseCases.swift`**

```swift
import Foundation

public struct DiscoverMedia: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    public func callAsFunction(
        _ filter: MediaFilter,
        page: Int = 1
    ) async throws -> ResultPage<MediaItem> {
        try await repository.discover(filter, page: max(page, 1))
    }
}

public struct SearchMedia: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    /// Returns an empty page without touching the repository when the text is too short.
    public func callAsFunction(
        _ rawText: String,
        kind: MediaKind? = nil,
        page: Int = 1
    ) async throws -> ResultPage<MediaItem> {
        guard let query = SearchQuery(rawText, kind: kind) else { return .empty }
        return try await repository.search(query, page: max(page, 1))
    }
}

public struct GetMediaDetails: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ id: MediaID) async throws -> MediaDetails {
        try await repository.details(of: id)
    }
}
```

## Tests

**`Packages/SampleTVDomain/Tests/SampleTVDomainTests/SearchMediaTests.swift`**

```swift
import Testing
@testable import SampleTVDomain

private final class SpyRepository: MediaRepository, @unchecked Sendable {
    private(set) var searchCalls = 0

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> {
        searchCalls += 1
        return .empty
    }
    func details(of id: MediaID) async throws -> MediaDetails {
        MediaDetails(item: MediaItem(id: id, title: "x"))
    }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

struct SearchMediaTests {
    @Test func shortTextNeverReachesRepository() async throws {
        let repository = SpyRepository()
        let page = try await SearchMedia(repository: repository)(" a ")
        #expect(page == .empty)
        #expect(repository.searchCalls == 0)
    }

    @Test func validTextIsTrimmedAndForwarded() async throws {
        let repository = SpyRepository()
        _ = try await SearchMedia(repository: repository)("  dark  ")
        #expect(repository.searchCalls == 1)
        #expect(SearchQuery("  dark  ")?.text == "dark")
    }
}
```

**`Packages/SampleTVDomain/Tests/SampleTVDomainTests/MediaFilterTests.swift`**

```swift
import Testing
@testable import SampleTVDomain

struct MediaFilterTests {
    private func item(
        kind: MediaKind = .tv, year: Int? = 2010, genres: [Int] = [18], rating: Double? = 8
    ) -> MediaItem {
        MediaItem(
            id: MediaID(kind: kind, value: 1), title: "T", releaseYear: year,
            genreIDs: genres, rating: rating
        )
    }

    @Test func emptyFilterAcceptsAnyItemOfTheSameKind() {
        #expect(MediaFilter(kind: .tv).matches(item()))
        #expect(!MediaFilter(kind: .movie).matches(item()))
    }

    @Test func genreMatchesIfAnySelectedGenreIsPresent() {
        #expect(MediaFilter(genreIDs: [18, 35]).matches(item(genres: [35])))
        #expect(!MediaFilter(genreIDs: [80]).matches(item(genres: [35])))
    }

    @Test func yearAndRatingBoundsAreInclusive() {
        let filter = MediaFilter(years: 2010...2012, minimumRating: 8)
        #expect(filter.matches(item(year: 2010, rating: 8)))
        #expect(!filter.matches(item(year: 2013)))
        #expect(!filter.matches(item(rating: 7.9)))
        #expect(!filter.matches(item(year: nil)))
    }
}
```

Add cases for: `ResultPage.hasNextPage`, `DiscoverMedia` clamping `page` to ≥ 1, `SearchQuery` rejecting whitespace-only
input, and `MediaFilter.matches` with `kind` mismatch. Target ≥ 90% line coverage for this package.

## Verify

```bash
cd Packages/SampleTVDomain
xcodebuild test -scheme SampleTVDomain -destination "id=$UDID" -enableCodeCoverage YES
cd ../.. && swiftlint lint --quiet | grep -c "error:"        # 0
grep -rE "^import " Packages/SampleTVDomain/Sources | sort -u  # only: import Foundation
```

`swift test` does not work here (the package targets tvOS); use `xcodebuild`.

## Definition of done

- [ ] `SampleTVDomain` builds and its tests pass; coverage ≥ 90%.
- [ ] Only `import Foundation` appears under `Sources/`.
- [ ] Package is linked to the app target and the app still builds.
- [ ] CI green; status table and `CHANGELOG.md` updated.

## Next

[Phase 3](../../Phase03_API_Layer/Documentation/Phase_03_API_Layer.md): implement `MediaRepository` against TMDB.
