# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org).

## [Unreleased]

- Phase 2: Domain layer (`SampleTVDomain` package) - entities, query types, `MediaRepository`, use cases, comprehensive tests.
- Phase 3: API layer (`SampleTVAPI` package) - TMDB client, media repository implementation, retry logic, error mapping.
- Phase 4: Movie discovery (`SampleTVUI`, `SampleTVDiscovery`) - browse grid with focusable cards, details modal, TMDB attribution, and wired into `AppContainer` and `RootView` using `@Observable`.
- Phase 5: Search (`SampleTVSearch`) - debounced search, filters, pagination.
- Phase 8: Authentication (`SampleTVAuth`) - mock login UI, session management, and authentication state persistence.
- Phase 9: Profile (`SampleTVProfile`) - profile switcher, user preferences, and My List.
- Phase 10: Categories (`SampleTVDiscovery`) - genre shelves on Discover, a dedicated Categories tab, progress overlay on `MediaCard`, and category/kind filter controls in `SampleTVSearch` 
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
