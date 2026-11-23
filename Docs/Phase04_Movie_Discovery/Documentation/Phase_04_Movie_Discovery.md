# Phase 4: Movie discovery

| | |
|---|---|
| Branch | `feature/phase_04_movie_discovery` |
| Depends on | Phases 2 and 3 |
| Delivers | `SampleTVUI` (shared components) and `SampleTVDiscovery` (browse grid and details screen), wired into the app |

## Deliverables

```
Packages/SampleTVUI/
├── Package.swift                              depends on SampleTVDomain
├── Sources/SampleTVUI/{ImageURLBuilder,MediaCard}.swift
└── Tests/SampleTVUITests/ImageURLBuilderTests.swift

Packages/SampleTVDiscovery/
├── Package.swift                              depends on SampleTVDomain, SampleTVUI
├── Sources/SampleTVDiscovery/
│   ├── DiscoveryViewModel.swift               paged loading, state enum
│   ├── DiscoveryView.swift                    focusable poster grid, infinite scroll
│   ├── ErrorView.swift                        offline / unauthorized / generic messages with retry
│   ├── DetailsViewModel.swift
│   └── DetailsView.swift                      poster, overview, genres, Play button
└── Tests/SampleTVDiscoveryTests/DiscoveryViewModelTests.swift
```

`SampleTVUI` exists so Discovery and Search can share `MediaCard` without importing each other.

## Design

- **State enum, not flags.** `DiscoveryViewModel.State` is `idle | loading | loaded([MediaItem]) | failed(MediaError)`.
  The view renders the state; it holds no loading booleans.
- **`@Observable` + `.task(id:)`.** The view runs `viewModel.reload()` in `.task(id: viewModel.filter)`: SwiftUI cancels
  the old task and starts a new one when the filter changes. View models ignore `CancellationError`.
- **Pagination.** `loadNextPage()` appends. The last card's `.task` triggers the next page while `canLoadMore`
  is true (`page < totalPages`).
- **tvOS focus.** Cards are `Button`s with `.buttonStyle(.card)`, which gives the standard focus lift and parallax.
  Do not use `.onTapGesture`; the Siri Remote drives focus, not touch.
- **Images.** `ImageURLBuilder` turns TMDB poster paths into URLs; `AsyncImage` loads them (cached by `URLCache`).
  A missing poster shows a placeholder.
- **Navigation lives in the app target.** `DiscoveryView` calls `onSelect(item)`; the app decides what happens.
  `DetailsView` calls `onPlay(item)`; that is wired to the player in Phase 6.

## Steps

1. Branch; create both packages; add them with **Add Local…**; link `SampleTVDiscovery` to the app target
   (`SampleTVUI` comes along transitively).
2. Add the code and tests below.
3. Extend `AppContainer` with `makeDiscoveryViewModel()` and `makeDetailsViewModel(for:)` (the final container is in
   [Phase 6](../../Phase06_Player_Feature/Documentation/Phase_06_Player_Feature.md)).
4. In `RootView`, show `DiscoveryView` inside a `NavigationStack`. Set a `@State var selection: MediaItem?` from
   `onSelect` and present `DetailsView` with `.fullScreenCover(item: $selection)`. On tvOS the Menu button dismisses it.
   Leave the Play button inert until Phase 6.
5. **TMDB attribution.** Show "This product uses the TMDB API but is not endorsed or certified by TMDB." with the
   TMDB logo (download it from TMDB's brand assets page) in the details footer or an About screen. This is a
   requirement of TMDB's terms.
6. Optional stretch: a genre row using `repository.genres(for:)` that mutates `viewModel.filter.genreIDs`.

## Code

### SampleTVUI

**`Packages/SampleTVUI/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVUI",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVUI", targets: ["SampleTVUI"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain")
    ],
    targets: [
        .target(
            name: "SampleTVUI",
            dependencies: [.product(name: "SampleTVDomain", package: "SampleTVDomain")]
        ),
        .testTarget(
            name: "SampleTVUITests",
            dependencies: ["SampleTVUI"]
        )
    ]
)
```

**`Packages/SampleTVUI/Sources/SampleTVUI/ImageURLBuilder.swift`**

```swift
import Foundation

public enum PosterSize: String, Sendable {
    case w185, w342, w500, w780
}

public struct ImageURLBuilder: Sendable {
    public var baseURL = URL(string: "https://image.tmdb.org/t/p")!

    public init() {}

    public func url(for path: String?, size: PosterSize) -> URL? {
        guard let path else { return nil }
        return baseURL.appending(path: size.rawValue).appending(path: path)
    }
}
```

**`Packages/SampleTVUI/Sources/SampleTVUI/MediaCard.swift`**

```swift
import SampleTVDomain
import SwiftUI

public struct PosterImage: View {
    private let url: URL?

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(2 / 3, contentMode: .fit)
            default:
                Rectangle()
                    .fill(.quaternary)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .overlay { Image(systemName: "film").font(.largeTitle) }
            }
        }
    }
}

/// Focusable poster card. Wrap in a `Button` with `.buttonStyle(.card)` at the call site.
public struct MediaCard: View {
    private let item: MediaItem
    private let images: ImageURLBuilder

    public init(item: MediaItem, images: ImageURLBuilder = ImageURLBuilder()) {
        self.item = item
        self.images = images
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PosterImage(url: images.url(for: item.posterPath, size: .w342))
            Text(item.title).font(.callout).lineLimit(1)
            if let year = item.releaseYear {
                Text(String(year)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
```

**`Packages/SampleTVUI/Tests/SampleTVUITests/ImageURLBuilderTests.swift`**

```swift
import Testing
@testable import SampleTVUI

struct ImageURLBuilderTests {
    @Test func buildsSizedURLFromLeadingSlashPath() {
        let url = ImageURLBuilder().url(for: "/abc.jpg", size: .w342)
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w342/abc.jpg")
    }

    @Test func nilPathGivesNoURL() {
        #expect(ImageURLBuilder().url(for: nil, size: .w342) == nil)
    }
}
```

### SampleTVDiscovery

**`Packages/SampleTVDiscovery/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVDiscovery",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVDiscovery", targets: ["SampleTVDiscovery"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI")
    ],
    targets: [
        .target(
            name: "SampleTVDiscovery",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI")
            ]
        ),
        .testTarget(
            name: "SampleTVDiscoveryTests",
            dependencies: ["SampleTVDiscovery"]
        )
    ]
)
```

**`Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/DiscoveryViewModel.swift`**

```swift
import Observation
import SampleTVDomain

@MainActor
@Observable
public final class DiscoveryViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([MediaItem])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var canLoadMore = false
    public var filter: MediaFilter

    private let discover: DiscoverMedia
    private var items: [MediaItem] = []
    private var nextPage = 1

    public init(discover: DiscoverMedia, filter: MediaFilter = MediaFilter()) {
        self.discover = discover
        self.filter = filter
    }

    /// Reloads from page 1. Call from `.task` and whenever `filter` changes.
    public func reload() async {
        items = []
        nextPage = 1
        canLoadMore = false
        state = .loading
        await loadNextPage()
    }

    public func loadNextPage() async {
        do {
            let page = try await discover(filter, page: nextPage)
            items += page.items
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
            state = .loaded(items)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }
}
```

**`Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/DiscoveryView.swift`**

```swift
import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DiscoveryView: View {
    @State private var viewModel: DiscoveryViewModel
    private let onSelect: (MediaItem) -> Void

    public init(viewModel: DiscoveryViewModel, onSelect: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    public var body: some View {
        content
            .task(id: viewModel.filter) { await viewModel.reload() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            ErrorView(error: error) { Task { await viewModel.reload() } }
        case .loaded(let items):
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 40)], spacing: 60) {
                    ForEach(items) { item in
                        Button { onSelect(item) } label: { MediaCard(item: item) }
                            .buttonStyle(.card)
                            .task {
                                if item == items.last, viewModel.canLoadMore {
                                    await viewModel.loadNextPage()
                                }
                            }
                    }
                }
                .padding(60)
            }
        }
    }
}
```

**`Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/ErrorView.swift`**

```swift
import SampleTVDomain
import SwiftUI

struct ErrorView: View {
    let error: MediaError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text(message)
        } actions: {
            if error != .unauthorized { Button("Try Again", action: retry) }
        }
    }

    private var title: String { error == .offline ? "You're Offline" : "Something Went Wrong" }
    private var symbol: String { error == .offline ? "wifi.slash" : "exclamationmark.triangle" }

    private var message: String {
        switch error {
        case .offline: "Check your connection and try again."
        case .unauthorized: "The TMDB token is missing or invalid. See the README."
        case .notFound: "That title could not be found."
        case .rateLimited: "Too many requests. Try again in a moment."
        case .server, .decoding, .unknown: "Please try again later."
        }
    }
}
```

**`Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/DetailsViewModel.swift`**

```swift
import Observation
import SampleTVDomain

@MainActor
@Observable
public final class DetailsViewModel {
    public enum State: Equatable {
        case loading
        case loaded(MediaDetails)
        case failed(MediaError)
    }

    public private(set) var state: State = .loading
    public let item: MediaItem

    private let getDetails: GetMediaDetails

    public init(item: MediaItem, getDetails: GetMediaDetails) {
        self.item = item
        self.getDetails = getDetails
    }

    public func load() async {
        state = .loading
        do {
            state = .loaded(try await getDetails(item.id))
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }
}
```

**`Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/DetailsView.swift`**

```swift
import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DetailsView: View {
    @State private var viewModel: DetailsViewModel
    private let onPlay: (MediaItem) -> Void

    public init(viewModel: DetailsViewModel, onPlay: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onPlay = onPlay
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 60) {
            PosterImage(url: ImageURLBuilder().url(for: viewModel.item.posterPath, size: .w500))
                .frame(width: 400)
            VStack(alignment: .leading, spacing: 24) {
                Text(viewModel.item.title).font(.largeTitle)
                Text(viewModel.item.overview)
                if case .loaded(let details) = viewModel.state {
                    Text(details.genres.map(\.name).joined(separator: " · ")).foregroundStyle(.secondary)
                }
                Button("Play") { onPlay(viewModel.item) }
            }
        }
        .padding(60)
        .task { await viewModel.load() }
    }
}
```

## Tests

**`Packages/SampleTVDiscovery/Tests/SampleTVDiscoveryTests/DiscoveryViewModelTests.swift`**

```swift
import Testing
import SampleTVDomain
@testable import SampleTVDiscovery

private struct StubRepository: MediaRepository {
    var result: Result<ResultPage<MediaItem>, MediaError>

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { try result.get() }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.unknown }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

@MainActor
struct DiscoveryViewModelTests {
    private let item = MediaItem(id: MediaID(kind: .tv, value: 1), title: "Show")

    @Test func reloadPublishesItems() async {
        let page = ResultPage(items: [item], page: 1, totalPages: 2)
        let model = DiscoveryViewModel(discover: DiscoverMedia(repository: StubRepository(result: .success(page))))
        await model.reload()
        #expect(model.state == .loaded([item]))
        #expect(model.canLoadMore)
    }

    @Test func failureSurfacesDomainError() async {
        let model = DiscoveryViewModel(
            discover: DiscoverMedia(repository: StubRepository(result: .failure(.offline)))
        )
        await model.reload()
        #expect(model.state == .failed(.offline))
    }
}

@MainActor
struct DetailsViewModelTests {
    @Test func loadPublishesDetails() async {
        let item = MediaItem(id: MediaID(kind: .movie, value: 603), title: "The Matrix")
        let details = MediaDetails(item: item, genres: [Genre(id: 28, name: "Action")])
        let repository = DetailsRepository(details: details)
        let model = DetailsViewModel(item: item, getDetails: GetMediaDetails(repository: repository))
        await model.load()
        #expect(model.state == .loaded(details))
    }
}

private struct DetailsRepository: MediaRepository {
    let details: MediaDetails
    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func details(of id: MediaID) async throws -> MediaDetails { details }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}
```

Add cases for: pagination appends and stops when `hasNextPage` is false; `reload()` resets items and page; cancellation
does not set `.failed`; `DetailsViewModel` failure state. Target ≥ 85% coverage for view-model code.

Add one **UI test** (`SampleTVUITests`): launch with a launch argument that makes `AppContainer` use a stub repository,
move focus with `XCUIRemote.shared.press(.right)`, press `.select`, and assert the details title exists. Keep stub
repositories in a test-only/`#if DEBUG` location in the app target so production code never ships fakes.

## Verify

```bash
for p in SampleTVUI SampleTVDiscovery; do
  (cd Packages/$p && xcodebuild test -scheme $p -destination "id=$UDID" -enableCodeCoverage YES)
done
xcodebuild test -scheme SampleTV -destination "id=$UDID"        # includes the UI test
swiftlint lint --quiet | grep -c "error:"                       # 0
```

Run the app with a real token and check manually: grid loads, focus moves with the arrow keys, scrolling loads
page 2, airplane-mode shows "You're Offline" with Try Again, a bad token shows the token message (no retry button).

## Definition of done

- [ ] Discovery grid and details screen work against live TMDB data and against a stub (previews/UI test).
- [ ] Errors are shown for offline, unauthorized and server failures; retry works where it makes sense.
- [ ] No feature package imports `SampleTVAPI` or another feature package (lint rules green).
- [ ] TMDB attribution is visible in the app.
- [ ] Package tests pass; coverage ≥ 85% for view models; CI green; docs and changelog updated.

## Next

[Phase 5](../../Phase05_Search_Module/Documentation/Phase_05_Search_Module.md): search and filtering.
