# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org).

## [Unreleased]

### Changed
- **Phase 15 (Playback Reliability, Data Hygiene & Error Recovery):** Replaced HTTP 403 streams in `CatalogPlaybackResourceResolver` with verified 200-OK Apple/Mux/Unified Streaming HLS streams; added `player.pause()` + `attemptID` retry recovery and opaque error overlay (`Try Again` / `Close`) in `PlayerViewModel`/`PlayerView`; enforced `SavePlaybackProgress.minimumSavedPosition = 5` (bypassed when watched); clamped TMDB `.newest` release/air dates to UTC today and ensured single `vote_count.gte=100` for `.rating` sort; scoped `DiscoveryViewModel.loadContinueWatching` by active `kind`, wired initial user profile/preferences into Discover, preserved selected media/trailer titles into playback metadata, and added `SearchViewModel.retry()` error recovery.
- **Phase 14 (Presentation Refactoring):** Extracted `PosterImage`, `ErrorView`, and `PaginationController` into `SampleTVUI`; added `PlayerViewModel` (removing `Combine` workspace-wide) and `SampleTVPlayerTests`; introduced `CategoriesViewModel` and `CategoryResultsViewModel`; wired `DiscoveryViewModel`, `DetailsViewModel`, and `ProfileViewModel` exclusively to Domain use cases; split `ProfileView` into modular `Sections/` with `#if DEBUG` preview fixtures; decomposed `RootView` and `AppContainer` into `Navigation/` (`RootView`, `RootViewModel`, `DetailsScreen`, `PlayerScreen`) and `AppContainer+Factories`.
- **Phase 13 (Clean Architecture & Domain/Data Modularization):** Reorganized `SampleTVDomain` into feature subdirectories (`Media/`, `Auth/`, `Profile/`, `Watchlist/`, `Playback/`), added `ViewerProfile.defaultID`, profile-scoped `PlaybackProgress`, playback progress use cases (`LoadPlaybackProgress`, `SavePlaybackProgress`, `ClearWatchHistory`, `GetContinueWatching`), and `ResolvePlaybackResources`.
- Split `SampleTVAPI/DTOs.swift` into single-DTO files and extracted SwiftData/Keychain/MockAuth persistence into a dedicated `SampleTVPersistence` package with a unified resilient `PersistenceContainer`.
- Hardened `.swiftlint.yml` with `SampleTVUI`/`SampleTVPersistence`/`SampleTVPlaybackProgress` boundary rules and `no_combine`, resolving all existing lint warnings.

## [2.0.0] - 2026-11-25

### Added
- **Phase 12 (`v2.0.0` release):** Watchlist (`WatchlistStore`, `GetWatchlist`, `ToggleWatchlist`, `IsInWatchlist` in `SampleTVDomain`; profile-scoped `SwiftDataWatchlistStore` in `SampleTVAPI`), **Add to My List** / **In My List** toggle in `DetailsView` (`SampleTVDiscovery`), **My List** shelf in `ProfileView` (`SampleTVProfile`), and `AppContainer` / `RootView` wiring.
- **UI Smoke Tests (`SampleTVUITests`) & DI Tests (`SampleTVTests`):** Added tvOS Siri Remote XCUITest smoke suite (`testDemoLoginAndTabNavigation`, `testLaunchPerformance`) with `-reset-auth` deterministic test launch and `AppContainerTests` unit tests.
- Phase 2: Domain layer (`SampleTVDomain` package) - entities, query types, `MediaRepository`, use cases, comprehensive tests.
- Phase 3: API layer (`SampleTVAPI` package) - TMDB client, media repository implementation, retry logic, error mapping.
- Phase 4: Movie discovery (`SampleTVUI`, `SampleTVDiscovery`) - browse grid with focusable cards, details modal, TMDB attribution, and wired into `AppContainer` and `RootView` using `@Observable`.
- Phase 5: Search (`SampleTVSearch`) - debounced search, filters, pagination.
- Phase 6 / 7 / 7b: Player (`SampleTVPlayer`) & Continue Watching (`SampleTVPlaybackProgress`) - `AVKit` player, `UserDefaults` progress store, progress persistence.
- Phase 8: Authentication (`SampleTVAuth`) - mock login UI, session management, and authentication state persistence.
- Phase 9: Profile (`SampleTVProfile`) - profile switcher, user preferences, and My List foundation.
- Phase 10: Categories (`SampleTVDiscovery`, `SampleTVSearch`) - genre shelves on Discover, a dedicated Categories tab, progress overlay on `MediaCard`, and category/kind filter controls in `SampleTVSearch`.
- Phase 11: Trailers & Playback (`SampleTVAPI`, `SampleTVDiscovery`, `SampleTVPlayer`) - TMDB `/videos` decoding, `PlaybackResourceResolver` mapping titles/genres to distinct public HLS/MP4 streams, **Play** / **Resume** / **Watch Trailer** CTAs, Recommendations on `DetailsView`, and player metadata.

## [0.1.0] - 2026-11-23

### Changed
- Phase order is now Foundation → Domain → API → Discovery → Search → Player, so the API layer can implement protocols the Domain defines.
- **Phase 1:** Removed Xcode template code (`Item.swift`, `ContentView.swift` with SwiftData); replaced with foundation skeleton.
- Added Swift 6 language mode (`SWIFT_VERSION: 6.0`) to all targets.
- Created `AppConfiguration`: reads TMDB token from Info.plist via `Secrets.xcconfig`, validates presence vs placeholder.
- Created `AppContainer`: composition root for dependency injection; Phases 2-6 will wire in repository, use cases, and factories.
- Created `RootView`: shows "SampleTV" title when token exists; otherwise shows "TMDB token missing" placeholder message instead of crashing.
- Converted Xcode project to universal `project.pbxproj` format with `TVOS_DEPLOYMENT_TARGET = 17.0`.

### Added
- Planning documentation: README, AGENTS, architecture, API specification, project structure, release process, PR template and one implementation guide per phase.
- Verified templates in `Docs/templates/` (SwiftLint with architecture-boundary rules, CI workflow, xcconfig secrets, `.gitignore`).
- Foundation skeleton: `AppConfiguration`, `AppContainer`, `RootView`, `AppConfigurationTests`.
- GitHub Actions CI: SwiftLint error testing (`fail-fast`) and tvOS app build and test.
