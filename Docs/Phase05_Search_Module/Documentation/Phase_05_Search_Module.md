# Phase 5: Search

| | |
|---|---|
| Branch | `feature/phase_05_search_module` |
| Depends on | Phases 2-4 |
| Delivers | `SampleTVSearch`: debounced search with client-side filtering and pagination, wired as a Search tab |

## Deliverables

```
Packages/SampleTVSearch/
├── Package.swift                      depends on SampleTVDomain, SampleTVUI
├── Sources/SampleTVSearch/
│   ├── SearchViewModel.swift          state, debounce, filter, paging
│   └── SearchView.swift               .searchable + results grid
└── Tests/SampleTVSearchTests/SearchViewModelTests.swift
```

No query-builder classes are needed. Earlier drafts planned `SearchQueryBuilder`, `YearRangeBuilder` and a Combine
`Debouncer`; the Domain types (`SearchQuery`, `MediaFilter`) and SwiftUI's task cancellation already cover that.

## Design

- **Debounce without Combine.** `.task(id: Key(text:filter:))` restarts whenever the input changes and cancels the
  previous task. `performSearch()` sleeps 300 ms first; if input changes again the sleep throws `CancellationError` and
  the stale search never runs. Test it with a tiny `debounce` value.
- **Minimum length** is enforced by the Domain (`SearchQuery` is `nil` below 2 characters); below it the view model
  returns to `.idle` without a request.
- **Filtering.** TMDB's `search/*` endpoints cannot filter by genre, year range or rating, so the view model applies
  `MediaFilter.matches(_:)` to each page of results. A consequence: a filtered page can contain fewer items than TMDB
  returned, so keep loading the next page when the grid is not full (the last-card `.task` already does).
  If you need server-side filtering, use `DiscoverMedia` instead; do not fake it with search.
- **Kind.** `filter.kind` selects `search/movie` or `search/tv`. Offer a Movies/TV segmented control. If you want a
  mixed list, call the use case with `kind: nil`, which maps to `search/multi`.
- **tvOS.** `.searchable` gives the system keyboard/search layout. The Search tab uses `role: .search`.
- **Empty states.** `ContentUnavailableView.search(text:)` for no results, a prompt when idle.

## Steps

1. Branch; create the package; add it with **Add Local…**; link `SampleTVSearch` to the app target.
2. Add the code and tests.
3. Add `makeSearchViewModel()` to `AppContainer`, and a **Search** tab to `RootView` (final code in Phase 6). The search tab
   wraps `SearchView` in its own `NavigationStack` and reuses the same `selection` → details cover as Discovery.
4. Add filter controls (genre, year range, minimum rating) bound to `viewModel.filter`. Load genre names with
   `repository.genres(for:)`; do not hard-code ids (TV and movie lists differ).

## Code

**`Packages/SampleTVSearch/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVSearch",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVSearch", targets: ["SampleTVSearch"])
    ],
    dependencies: [
        .package(path: "../SampleTVDomain"),
        .package(path: "../SampleTVUI")
    ],
    targets: [
        .target(
            name: "SampleTVSearch",
            dependencies: [
                .product(name: "SampleTVDomain", package: "SampleTVDomain"),
                .product(name: "SampleTVUI", package: "SampleTVUI")
            ]
        ),
        .testTarget(
            name: "SampleTVSearchTests",
            dependencies: ["SampleTVSearch"]
        )
    ]
)
```

**`Packages/SampleTVSearch/Sources/SampleTVSearch/SearchViewModel.swift`**

```swift
import Observation
import SampleTVDomain

@MainActor
@Observable
public final class SearchViewModel {
    public enum State: Equatable {
        case idle
        case loaded([MediaItem])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var canLoadMore = false
    public var text = ""
    public var filter = MediaFilter(kind: .tv)

    private let search: SearchMedia
    private let debounce: Duration
    private var items: [MediaItem] = []
    private var nextPage = 1

    public init(search: SearchMedia, debounce: Duration = .milliseconds(300)) {
        self.search = search
        self.debounce = debounce
    }

    /// Drive from `.task(id: SearchKey(text:filter:))`. SwiftUI cancels the previous task when the
    /// input changes, so the sleep is the debounce and no Combine pipeline is needed.
    public func performSearch() async {
        do {
            try await Task.sleep(for: debounce)
            items = []
            nextPage = 1
            await loadNextPage()
        } catch {
            return // cancelled by newer input
        }
    }

    public func loadNextPage() async {
        guard SearchQuery(text) != nil else {
            state = .idle
            canLoadMore = false
            return
        }
        do {
            let page = try await search(text, kind: filter.kind, page: nextPage)
            items += page.items.filter(filter.matches)
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

**`Packages/SampleTVSearch/Sources/SampleTVSearch/SearchView.swift`**

```swift
import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let onSelect: (MediaItem) -> Void

    public init(viewModel: SearchViewModel, onSelect: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    private struct Key: Equatable {
        let text: String
        let filter: MediaFilter
    }

    public var body: some View {
        results
            .searchable(text: $viewModel.text)
            .task(id: Key(text: viewModel.text, filter: viewModel.filter)) {
                await viewModel.performSearch()
            }
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search Movies and Shows", systemImage: "magnifyingglass")
        case .failed:
            ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle")
        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView.search(text: viewModel.text)
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

## Tests

**`Packages/SampleTVSearch/Tests/SampleTVSearchTests/SearchViewModelTests.swift`**

```swift
import SampleTVDomain
import Testing
@testable import SampleTVSearch

private struct StubRepository: MediaRepository {
    var page: ResultPage<MediaItem> = .empty

    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem> { .empty }
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem> { self.page }
    func details(of id: MediaID) async throws -> MediaDetails { throw MediaError.unknown }
    func genres(for kind: MediaKind) async throws -> [Genre] { [] }
}

@MainActor
struct SearchViewModelTests {
    private func item(_ value: Int, genres: [Int]) -> MediaItem {
        MediaItem(id: MediaID(kind: .tv, value: value), title: "T\(value)", genreIDs: genres)
    }

    @Test func shortTextStaysIdle() async {
        let model = SearchViewModel(search: SearchMedia(repository: StubRepository()), debounce: .milliseconds(1))
        model.text = "a"
        await model.performSearch()
        #expect(model.state == .idle)
    }

    @Test func resultsAreFilteredOnTheClient() async {
        let page = ResultPage(items: [item(1, genres: [18]), item(2, genres: [35])], page: 1, totalPages: 1)
        let model = SearchViewModel(
            search: SearchMedia(repository: StubRepository(page: page)), debounce: .milliseconds(1)
        )
        model.text = "show"
        model.filter = MediaFilter(kind: .tv, genreIDs: [35])
        await model.performSearch()
        #expect(model.state == .loaded([item(2, genres: [35])]))
    }
}
```

Add cases for: debounce coalescing (call `performSearch()` in a task, cancel it, assert the repository was not
called), paging appends and honours `canLoadMore`, errors map to `.failed`, and switching `filter.kind` restarts from
page 1. Target ≥ 85% coverage.

## Verify

```bash
cd Packages/SampleTVSearch && xcodebuild test -scheme SampleTVSearch -destination "id=$UDID" -enableCodeCoverage YES
cd ../.. && xcodebuild test -scheme SampleTV -destination "id=$UDID"
swiftlint lint --quiet | grep -c "error:"       # 0
```

Manual: type quickly and confirm only one request fires after you pause (watch the network in a proxy, or add a
temporary counter in a debug repository); a one-letter query shows the prompt, not an error.

## Definition of done

- [ ] Search works against live data with debounce, paging, and client-side filters.
- [ ] Short or empty text never triggers a request.
- [ ] `SampleTVSearch` does not import `SampleTVAPI` or `SampleTVDiscovery`.
- [ ] Tests pass; coverage ≥ 85%; CI green; docs and changelog updated.

## Next

[Phase 6](../../Phase06_Player_Feature/Documentation/Phase_06_Player_Feature.md): playback.
