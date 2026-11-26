# Phase 13: Clean Architecture & Domain/Data Modularization

| | |
|---|---|
| Branch | `feature/phase_13_arch_domain_data_cleanup` |
| Depends on | Phase 12 (`v2.0.0`) |
| Delivers | One-primary-type-per-file `SampleTVDomain` & `SampleTVAPI` cleanup, complete Domain use cases (incl. Continue Watching & Playback Progress), dedicated `SampleTVPersistence` package separated from TMDB REST API, unified SwiftData container, test-stub isolation, and stricter `.swiftlint.yml` architecture/no-Combine rules |

## Audit Findings Addressed

1. **Kitchen-sink `SampleTVAPI`:** Currently mixes TMDB HTTP networking (`TMDBClient`, `DTOs`, `TMDBMediaRepository`), Keychain auth (`KeychainSessionStore`, `MockAuthRepository`), SwiftData persistence (`SwiftDataModels`, `SwiftDataProfileRepository`, `SwiftDataWatchlistStore`), static playback stream mapping (`CatalogPlaybackResourceResolver`), and test doubles (`UserDefaultsSessionStore` exported in production).
2. **God files with mixed types:**
   - `SampleTVDomain/Entities.swift` (8 unrelated types: media entities, `UserAccount`, `ResultPage`).
   - `SampleTVDomain/UseCases.swift` (mixes `AuthError` + `AuthRepository` + Auth use cases alongside Media use cases).
   - `SampleTVAPI/DTOs.swift` (8 DTO structs + Domain mappers in one 154-line file).
   - `SampleTVAPI/SwiftDataModels.swift` (3 `@Model` classes + `MediaItem` mapping in one file).
   - `SampleTVAPI/KeychainSessionStore.swift` (mixes `SessionStore` protocol, `KeychainSessionStore`, and test helper `UserDefaultsSessionStore`).
3. **Missing / bypassed Domain contracts:**
   - `PlaybackProgressStore` has no Domain use cases (`LoadPlaybackProgress`, `SavePlaybackProgress`, `ClearWatchHistory`, `GetContinueWatching`), forcing Views and ViewModels to call stores directly.
   - `PlaybackProgress` is global rather than profile-scoped (`profileID`), unlike `UserPreferences` and `WatchlistStore`.
   - `PlaybackResourceResolver` has no Domain use case (`ResolvePlaybackResources`), and `"main"` is hardcoded as a magic `profileID` across multiple packages instead of `ViewerProfile.defaultID`.
4. **Two separate SwiftData containers & `fatalError` in `AppContainer.live()`:** `SwiftDataProfileRepository` and `SwiftDataWatchlistStore` each create separate `ModelContainer` instances and crash via `fatalError` on setup failure.
5. **Lint gaps & existing warnings:** 14 existing SwiftLint warnings (`Categories.swift` `function_body_length`, `trailing_newline`, `line_length`), missing `SampleTVUI`/`SampleTVPlaybackProgress`/`SampleTVPersistence` coverage in `.swiftlint.yml`, and no rule banning `import Combine`.

## Deliverables

```text
Packages/SampleTVDomain/Sources/SampleTVDomain/
├── Media/
│   ├── MediaKind.swift                    MediaKind, VideoKind, MediaID
│   ├── Genre.swift                        Genre
│   ├── MediaItem.swift                    MediaItem
│   ├── MediaDetails.swift                 MediaVideo, MediaDetails
│   ├── ResultPage.swift                   ResultPage
│   ├── MediaError.swift                   MediaError
│   ├── MediaRepository.swift              MediaRepository protocol
│   ├── MediaQuery.swift                   MediaSort, MediaFilter, SearchQuery
│   ├── MediaUseCases.swift                DiscoverMedia, SearchMedia, GetMediaDetails
│   ├── MediaShelf.swift                   MediaShelf
│   └── CategoryUseCases.swift             GetGenres, GetDiscoveryShelves (split helpers <= 50 lines)
├── Auth/
│   ├── UserAccount.swift                  UserAccount, AuthError
│   ├── AuthRepository.swift               AuthRepository, SessionStore (or data port)
│   └── AuthUseCases.swift                 SignIn, SignInDemo, SignOut, LoadCurrentAccount
├── Profile/
│   ├── ViewerProfile.swift                ViewerProfile (incl. static let defaultID = "main"), UserPreferences
│   ├── ProfileRepository.swift            ProfileRepository protocol
│   └── ProfileUseCases.swift              GetCurrentUserProfile, GetProfiles, GetUserPreferences, UpdateUserPreferences, SwitchProfile
├── Watchlist/
│   ├── WatchlistStore.swift               WatchlistStore protocol
│   └── WatchlistUseCases.swift            GetWatchlist, ToggleWatchlist, IsInWatchlist
└── Playback/
    ├── PlaybackProgress.swift             PlaybackProgress (profile-scoped), PlaybackProgressStore
    ├── PlaybackProgressUseCases.swift     LoadPlaybackProgress, SavePlaybackProgress, ClearWatchHistory, GetContinueWatching
    └── PlaybackResource.swift             PlaybackResourceKind, PlayableResource, PlaybackResourceResolver, ResolvePlaybackResources

Packages/SampleTVAPI/Sources/SampleTVAPI/
├── Client/                                Transport.swift, TMDBClient.swift, URLSession+TMDB.swift
├── DTOs/                                  PageDTO.swift, MediaDTO.swift, DetailsDTO.swift, VideoDTO.swift, GenreDTO.swift
├── Repositories/                          TMDBMediaRepository.swift
└── Catalog/                               CatalogPlaybackResourceResolver.swift

Packages/SampleTVPersistence/              (new local Swift package — registered in workspace & linked via Scripts/link_package.rb)
├── Package.swift                          depends on SampleTVDomain
├── Sources/SampleTVPersistence/
│   ├── PersistenceContainer.swift         single shared SwiftData ModelContainer builder
│   ├── Models/                            StoredProfile.swift, StoredPreferences.swift, StoredWatchlistItem.swift, StoredProgress.swift
│   ├── Profile/                           SwiftDataProfileRepository.swift
│   ├── Watchlist/                         SwiftDataWatchlistStore.swift
│   ├── Progress/                          SwiftDataPlaybackProgressStore.swift (or clean adapter replacing/migrating UserDefaults)
│   └── Auth/                              SessionStore.swift, KeychainSessionStore.swift, MockAuthRepository.swift
└── Tests/SampleTVPersistenceTests/        migrated SwiftData/Auth/UserDefaultsSessionStore (test-only) tests

.swiftlint.yml                             add SampleTVUI, SampleTVPersistence, SampleTVPlaybackProgress + no_combine rule; 0 warnings
```

## Design

- **Strict layer & package separation:**
  - `SampleTVDomain` stays `Foundation`-only, organized into cohesive subdirectories (`Media/`, `Auth/`, `Profile/`, `Watchlist/`, `Playback/`) with one primary type/use-case group per file.
  - `SampleTVAPI` strictly owns TMDB REST HTTP transport, DTOs, and `TMDBMediaRepository` (plus playback catalog resolution until a separate catalog service exists). All SwiftData models/repositories and Keychain/MockAuth code move out of `SampleTVAPI` into `SampleTVPersistence`.
  - Remove `UserDefaultsSessionStore` from production targets; define it inside test targets (`SampleTVPersistenceTests`) where it belongs.
- **Complete Domain Use Cases:** Every operation that Views or ViewModels perform against a repository/store gets an explicit Domain use case (`GetContinueWatching`, `LoadPlaybackProgress`, `SavePlaybackProgress`, `ClearWatchHistory`, `ResolvePlaybackResources`), plus `ViewerProfile.defaultID` eliminating hardcoded `"main"` literals.
- **Unified SwiftData storage:** `PersistenceContainer` owns one `ModelContainer` schema (`StoredProfile`, `StoredPreferences`, `StoredWatchlistItem`, and profile-scoped progress if migrated) and handles initialization cleanly without duplicating container setup across stores.
- **Strict `.swiftlint.yml` enforcement:** Add `SampleTVUI`, `SampleTVPersistence`, and `SampleTVPlaybackProgress` to feature-boundary custom rules, add `no_combine` (`import Combine` forbidden), and fix all 14 existing lint warnings (`function_body_length` in `GetDiscoveryShelves`, `line_length`, `trailing_newline`).

## Steps

1. Branch `feature/phase_13_arch_domain_data_cleanup` from `main`.
2. Reorganize `SampleTVDomain` into modular files, add `ViewerProfile.defaultID`, `PlaybackProgressUseCases` (`GetContinueWatching`, `LoadPlaybackProgress`, `SavePlaybackProgress`, `ClearWatchHistory`), `ResolvePlaybackResources`, and refactor `GetDiscoveryShelves` under 50 lines.
3. Split `SampleTVAPI/DTOs.swift` into one DTO per file and keep `SampleTVAPI` focused on TMDB networking + `CatalogPlaybackResourceResolver`.
4. Create `Packages/SampleTVPersistence`, register it in `SampleTV.xcworkspace/contents.xcworkspacedata`, link via `ruby Scripts/link_package.rb SampleTVPersistence`, migrate `SwiftData*`, `KeychainSessionStore`, and `MockAuthRepository` from `SampleTVAPI`, and move `UserDefaultsSessionStore` into tests only.
5. Update `AppContainer.swift` (and `SampleTVTests`/`SampleTVAPITests`) to import `SampleTVPersistence` and wire all new use cases.
6. Harden `.swiftlint.yml`, fix all existing warnings, and run full test + lint verification.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVDomain SampleTVAPI SampleTVPersistence SampleTVPlaybackProgress SampleTVUI SampleTVDiscovery SampleTVSearch SampleTVAuth SampleTVProfile; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```

## Definition of done

- `SampleTVAPI` contains zero SwiftData, Keychain, or Auth implementation files; `SampleTVPersistence` owns persistence and auth adapters.
- Every file in `SampleTVDomain`, `SampleTVAPI`, and `SampleTVPersistence` holds one primary type or cohesive group of small use cases (`0` SwiftLint warnings or errors).
- `UserDefaultsSessionStore` is test-only and no longer shipped in production modules.
- All packages and `SampleTVTests` pass with `swiftlint lint` clean (`0` errors, `0` warnings).

**Next:** [Phase 14: Presentation Refactoring — Thin Views, ViewModels & Composition](../../Phase14_Presentation_Refactoring/Documentation/Phase_14_Presentation_Refactoring.md)
