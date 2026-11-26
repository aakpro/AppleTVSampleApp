# Phase 14: Presentation Refactoring — Thin Views, ViewModels & Composition

| | |
|---|---|
| Branch | `feature/phase_14_presentation_refactoring` |
| Depends on | Phase 13 |
| Delivers | Zero business/data logic in SwiftUI `View`s, split `RootView` / `ProfileView` / `MediaCard` files, dedicated ViewModels for Categories, CategoryResults, and Player (removing `Combine`), shared `SampleTVUI` error/pagination abstractions, and `SampleTVPlayerTests` |

## Audit Findings Addressed

1. **`SampleTV/RootView.swift` (197-line mixed file doing data calls in Views):** Combines 5 types (`CategoryDestination`, `PlaybackSelection`, `RootView`, `DetailsScreen`, `PlayerScreen`) and calls `container.authRepository.currentAccount()`, `container.profileRepository.currentProfile()`, `container.resourceResolver.resolve(...)`, and `container.progressStore.loadProgress/saveProgress` directly inside SwiftUI `View`s.
2. **Views acting as ViewModels (`CategoriesView` & `CategoryResultsView`):** Directly invoke `GetGenres` and `DiscoverMedia` use cases, manage pagination state, and catch `CancellationError` / map `MediaError` inside SwiftUI `View` bodies.
3. **ViewModels bypassing Domain use cases:** `DiscoveryViewModel+ContinueWatching`, `DetailsViewModel`, and `ProfileViewModel` bypass `GetWatchlist`, `ToggleWatchlist`, `IsInWatchlist`, `GetContinueWatching`, `LoadPlaybackProgress`, `ClearWatchHistory`, and `LoadCurrentAccount` by injecting raw store/repository protocols directly.
4. **`SampleTVPlayer` violates Swift 6 / no-Combine rules and has zero tests:** `PlayerView.swift` imports `Combine` (`item.publisher(for: \.status)`), runs timers/observers inside the View, and `Packages/SampleTVPlayer/Package.swift` has no `.testTarget`.
5. **Monolithic & duplicated presentation files:**
   - `ProfileView.swift` (283 lines) embeds 6 sections + 4 mock preview repositories in production source.
   - `LoginView.swift` embeds `AuthError` string formatting + `PreviewRepo`.
   - `MediaCard.swift` combines `PosterImage` and `MediaCard`.
   - `ErrorView` lives privately in `SampleTVDiscovery` so `SearchView`, `CategoriesView`, `PlayerView`, and `ProfileView` duplicate or omit error UI.
   - Pagination logic is duplicated across `DiscoveryViewModel`, `SearchViewModel`, and `CategoryResultsView`.

## Deliverables

```text
SampleTV/
├── AppContainer.swift                     clean composition root + AppContainer+Factories.swift
├── Navigation/
│   ├── RootView.swift                     thin tab/session router bound to RootViewModel
│   ├── RootViewModel.swift                @MainActor @Observable (LoadCurrentAccount, GetCurrentUserProfile)
│   ├── DetailsScreen.swift                thin container + DetailsScreenViewModel (ResolvePlaybackResources)
│   └── PlayerScreen.swift                 thin container + PlayerScreenViewModel (LoadPlaybackProgress, SavePlaybackProgress)

Packages/SampleTVUI/Sources/SampleTVUI/
├── PosterImage.swift                      split out from MediaCard.swift
├── MediaCard.swift                        single primary view
├── ErrorView.swift                        shared ErrorView + MediaError/AuthError display helper
└── PaginationController.swift             reusable @MainActor pagination & CancellationError helper

Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
├── CategoriesViewModel.swift              @MainActor @Observable (GetGenres)
├── CategoriesView.swift                   thin view bound to CategoriesViewModel
├── CategoryResultsViewModel.swift         @MainActor @Observable (DiscoverMedia + pagination)
├── CategoryResultsView.swift              thin view bound to CategoryResultsViewModel
├── DiscoveryViewModel.swift               uses GetContinueWatching use case
└── DetailsViewModel.swift                 uses ToggleWatchlist, IsInWatchlist, LoadPlaybackProgress, ResolvePlaybackResources

Packages/SampleTVPlayer/
├── Package.swift                          add SampleTVPlayerTests testTarget
├── Sources/SampleTVPlayer/
│   ├── PlayerViewModel.swift              @MainActor @Observable (async status/progress, zero Combine)
│   └── PlayerView.swift                   thin AVKit wrapper bound to PlayerViewModel
└── Tests/SampleTVPlayerTests/
    └── PlayerViewModelTests.swift         progress timer, status transitions, metadata tests

Packages/SampleTVProfile/Sources/SampleTVProfile/
├── ProfileViewModel.swift                 uses LoadCurrentAccount, ClearWatchHistory, GetWatchlist
├── ProfileView.swift                      thin coordinator composing section views (<= 100 lines)
└── Sections/
    ├── AccountHeaderSection.swift
    ├── ProfileSwitcherSection.swift
    ├── PreferencesSection.swift
    ├── WatchHistorySection.swift
    └── WatchlistSection.swift

Packages/SampleTVAuth/Sources/SampleTVAuth/
└── LoginView.swift                        uses shared error display helper; preview stubs moved to #if DEBUG fixtures
```

## Design

- **Thin SwiftUI Views across every module:** Views own `@State private var viewModel` (plus pure UI presentation flags such as confirmation dialogs) and delegate every async call, state transition, pagination step, and error mapping to an `@MainActor @Observable final class` ViewModel. No View ever holds a repository, store, use case, or `AppContainer` call to fetch/save data directly.
- **ViewModels depend on Use Cases:** Update `DetailsViewModel`, `ProfileViewModel`, `DiscoveryViewModel`, `RootViewModel`, `DetailsScreenViewModel`, and `PlayerScreenViewModel` to invoke the Domain use cases introduced in Phase 12/13 (`GetWatchlist`, `ToggleWatchlist`, `IsInWatchlist`, `GetContinueWatching`, `LoadPlaybackProgress`, `SavePlaybackProgress`, `ClearWatchHistory`, `ResolvePlaybackResources`, `LoadCurrentAccount`).
- **No `Combine` anywhere:** Replace `item.publisher(for: \.status)` in `SampleTVPlayer` with async KVO `AsyncStream` / `NotificationCenter.default.notifications(named:)` inside `PlayerViewModel`, keeping Swift 6 concurrency structured and testable.
- **Single-responsibility files & clean `#Preview` separation:** Split `RootView.swift`, `ProfileView.swift`, `MediaCard.swift`, and `AppContainer.swift` so each file has one primary view or concern (under ~120 lines), move inline preview mocks out of production code into `#if DEBUG` preview fixtures (or test helpers), and move `ErrorView` into `SampleTVUI` for universal reuse.

## Steps

1. Branch `feature/phase_14_presentation_refactoring` from `main`.
2. Split `SampleTVUI/MediaCard.swift` into `PosterImage.swift` and `MediaCard.swift`; move `ErrorView` into `SampleTVUI` and add `PaginationController` (if helpful to deduplicate `Search`, `Discovery`, and `CategoryResults`).
3. Create `CategoriesViewModel` + `CategoryResultsViewModel` in `SampleTVDiscovery`, refactor `CategoriesView` and `CategoryResultsView` to thin views, and switch `DiscoveryViewModel` / `DetailsViewModel` to Domain use cases.
4. Create `PlayerViewModel` (removing `import Combine`) and `SampleTVPlayerTests` in `SampleTVPlayer`.
5. Split `ProfileView.swift` into modular section subviews, update `ProfileViewModel` to use Domain use cases, and extract preview fixtures out of `ProfileView.swift` and `LoginView.swift`.
6. Decompose `SampleTV/RootView.swift` (`RootView` + `RootViewModel`, `DetailsScreen`, `PlayerScreen`) and wire through `AppContainer` factories.
7. Run tests across all packages + `SampleTV` + `swiftlint lint --strict`.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVDomain SampleTVAPI SampleTVPersistence SampleTVPlaybackProgress SampleTVUI SampleTVDiscovery SampleTVSearch SampleTVPlayer SampleTVAuth SampleTVProfile; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```

## Definition of done

- Zero SwiftUI `View`s import or invoke repositories/stores/use cases directly; every async screen has a tested `@MainActor @Observable` ViewModel.
- Zero occurrences of `import Combine` across the entire workspace.
- `RootView.swift`, `ProfileView.swift`, and `MediaCard.swift` are split cleanly into single-purpose files without embedded mock repositories in production views.
- `SampleTVPlayer` has unit tests covering readiness, error state, and progress emission.
- All packages, app tests, and `swiftlint lint --strict` pass with 0 errors and 0 warnings.

**Next:** [Phase 15: Playback Reliability, Data Hygiene & Error Recovery](../../Phase15_Playback_And_Data_Polish/Documentation/Phase_15_Playback_And_Data_Polish.md)
