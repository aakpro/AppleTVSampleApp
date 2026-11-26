---
name: sampletv-clean-architecture
description: >-
  Enforces SampleTV Clean Architecture boundaries, single-purpose file modularity,
  thin SwiftUI views, use-case routing, and Swift 6 concurrency rules. Use before
  writing, refactoring, or reviewing any Swift package, ViewModel, View, or app
  composition file in SampleTV.
---

# SampleTV Clean Architecture & Modularity

Use this skill whenever adding features, refactoring packages, splitting files, or reviewing changes in SampleTV.

## Package & Layer Boundaries

1. **Domain (`SampleTVDomain`)** imports `Foundation` only. Organize files into feature subfolders (`Media/`, `Auth/`, `Profile/`, `Watchlist/`, `Playback/`) with one primary entity, protocol, or cohesive use-case group per file. Never dump unrelated entities (`UserAccount`, `ResultPage`, `MediaItem`) or mixed auth/media use cases into one file.
2. **Data packages stay single-purpose:**
   - `SampleTVAPI` owns TMDB HTTP transport, DTOs (one DTO file per response shape), `TMDBMediaRepository`, and stream catalog resolution.
   - Local persistence (SwiftData `@Model` schemas, unified `ModelContainer`, Keychain session store, auth mocks) belongs in `SampleTVPersistence` (or `SampleTVPlaybackProgress`), never mixed into `SampleTVAPI`.
   - Test doubles (`UserDefaultsSessionStore`, stub repositories) belong in test targets or `#if DEBUG` preview fixtures, never shipped in production library targets.
3. **Feature packages (`SampleTVAuth`, `SampleTVDiscovery`, `SampleTVSearch`, `SampleTVProfile`)** depend only on `SampleTVDomain` and `SampleTVUI`. Never import `SampleTVAPI`, `SampleTVPersistence`, or sibling feature packages.
4. **Shared presentation (`SampleTVUI`)** holds reusable components (`PosterImage`, `MediaCard`, `CategoryTile`, `MediaShelfRow`, `ErrorView`, `Theme`, `PaginationController`) and never imports `SampleTVAPI` or feature packages.
5. **App target (`SampleTV`)** is the composition root (`AppContainer`, `RootView`, screen wrappers). Keep `RootView`, `DetailsScreen`, and `PlayerScreen` in separate files.

## Thin Views & ViewModel Rules

1. **Zero business or data logic in SwiftUI `View`s:**
   - Views never hold or invoke repositories, persistence stores, `AppContainer` data calls, `DiscoverMedia`/`GetGenres` pagination state, or `CancellationError`/`MediaError` catch blocks directly.
   - Every screen with async loading, pagination, or persistence must bind to a dedicated `@MainActor @Observable final class` ViewModel (`CategoriesViewModel`, `CategoryResultsViewModel`, `PlayerViewModel`, `RootViewModel`, etc.).
2. **ViewModels call Domain Use Cases:** Route actions through Domain use cases (`GetWatchlist`, `ToggleWatchlist`, `IsInWatchlist`, `GetContinueWatching`, `LoadPlaybackProgress`, `SavePlaybackProgress`, `ClearWatchHistory`, `ResolvePlaybackResources`, `LoadCurrentAccount`) rather than calling raw `WatchlistStore` or `PlaybackProgressStore` protocols directly from ViewModels.
3. **No magic identifiers:** Reference `ViewerProfile.defaultID` (or Domain defaults) instead of scattering `"main"` literals across ViewModels and navigation views.
4. **No `Combine`:** Use Swift 6 structured concurrency (`async/await`, `AsyncStream`, `NotificationCenter.notifications(named:)`, `.task(id:)`). Never add `import Combine`.

## File Granularity Checklist

- Prefer **one primary type per file**; keep view files under ~150 lines by extracting section subviews into `Sections/`.
- Keep `#Preview` stub repositories/stores out of production view files (place in `#if DEBUG` preview fixtures).
- Never duplicate `ErrorView` or pagination state machines inside individual feature modules—reuse `SampleTVUI`.
- Run `swiftlint lint --strict` and package + app tests after every refactor:

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in Packages/*/; do
  name=$(basename "$pkg")
  (cd "$pkg" && xcodebuild test -scheme "$name" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```
