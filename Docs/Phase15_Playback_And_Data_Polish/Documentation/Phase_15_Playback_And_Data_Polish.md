# Phase 15: Playback Reliability, Data Hygiene & Error Recovery

| | |
|---|---|
| Branch | `feature/phase_15_playback_and_data_polish` |
| Depends on | Phase 14 |
| Delivers | Working non-403 feature/trailer streams, reliable `PlayerView` error recovery & progress thresholds, TMDB `New Releases` / `Top Rated` query hygiene, kind-filtered & profile-scoped Continue Watching, and retryable error states in Categories and Search |

## Deliverables

```text
Packages/SampleTVAPI/Sources/SampleTVAPI/
├── Catalog/CatalogPlaybackResourceResolver.swift  verified 200-OK HLS/MP4 catalog (remove dead 403 URLs)
└── Repositories/TMDBMediaRepository.swift         date-clamped New Releases + vote_count floor for Top Rated

Packages/SampleTVPlayer/Sources/SampleTVPlayer/
├── PlayerViewModel.swift                          reliable failure state + 5s minimum progress guard
└── PlayerView.swift                               opaque failure overlay (Close + Retry)

Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
├── DiscoveryViewModel+ContinueWatching.swift      filter Continue Watching by active MediaKind + profileID
├── DiscoveryViewModel.swift                       apply initial UserPreferences.defaultKind
└── CategoriesView.swift                           render shared ErrorView with retry

Packages/SampleTVSearch/Sources/SampleTVSearch/
└── SearchView.swift                               render shared ErrorView with retry on .failed

SampleTV/
├── AppContainer.swift                             wire profile defaultKind into DiscoveryViewModel
└── Navigation/DetailsScreen.swift                 preserve selected MediaItem/TMDB trailer title in PlayerScreen
```

## Design

- **Fix broken `403` streams and trailers:** `CatalogPlaybackResourceResolver` currently serves 7 URLs returning HTTP `403` (`bitdash-a.akamaihd.net` and `commondatastorage.googleapis.com`). Replace all broken entries with verified reachable public HLS/MP4 streams (`devstreaming-cdn.apple.com` variants, `demo.unified-streaming.com` *Tears of Steel*, or newly verified public streams). Keep `PlayableResource` metadata honest: display the selected `MediaItem.title` (and TMDB trailer name when available) in `PlayerView` instead of unrelated sample titles like `"Tears of Steel — Trailer"`.
- **Resilient `PlayerView` failure state:** On tvOS, `VideoPlayer` currently falls back to a blank black screen with a tiny red `⊘` when an asset fails to load. Ensure `PlayerViewModel` catches `AVPlayerItem.status == .failed` and `.AVPlayerItemFailedToPlayToEndTime`, and cover failed playback in `PlayerView` with an opaque dark backdrop, clear error copy, **Try Again**, and **Close** (`@Environment(\.dismiss)`).
- **Progress tracking hygiene:** Skip saving `PlaybackProgress` when `position < 5` seconds so opening and immediately closing a stream at `00:00` does not pollute *Continue Watching* and *Watch History* with empty bars.
- **TMDB query hygiene (`TMDBMediaRepository`):**
  - Inject `now: @Sendable () -> Date = Date.init` so tests remain deterministic.
  - On `MediaSort.newest`, set `primary_release_date.lte` (movies) / `first_air_date.lte` (TV) to today (`YYYY-MM-DD`) so *New Releases* stops surfacing unreleased 2031–2099 placeholder entries with missing artwork.
  - On `MediaSort.rating`, always apply `vote_count.gte=100` (matching the existing `minimumRating` guard) so *Top Rated* excludes obscure 1-vote `10/10` entries.
- **Kind-scoped Continue Watching & defaultKind preference:** Scope *Continue Watching* to both active `profileID` and `kind` (`item.id.kind == kind`) so switching *Discover* to **TV Shows** never shows movies, and initialize `DiscoveryViewModel.kind` from the active profile's `UserPreferences.defaultKind`.
- **Visible retryable errors:** Wire `CategoriesView` and `SearchView` `.failed` states to the shared `SampleTVUI` `ErrorView` with focusable **Try Again** buttons.

## Steps

1. Branch `feature/phase_15_playback_and_data_polish` from `main`.
2. Update `CatalogPlaybackResourceResolver.swift` (and affected tests) with verified reachable streams and pass accurate selected media/trailer titles from `DetailsScreen`.
3. Harden `PlayerViewModel` and `PlayerView` failure observation, opaque error overlay (**Try Again** / **Close**), and 5-second minimum progress guard.
4. Update `TMDBMediaRepository` (`newest` upper date bound + `rating` `vote_count.gte` floor) and add unit tests using `MockHTTPTransport` inspecting outgoing `URLQueryItem`s.
5. Update `DiscoveryViewModel+ContinueWatching.swift` (profile + kind filtering), initialize `DiscoveryViewModel.kind` from `UserPreferences.defaultKind`, and verify retryable `ErrorView` in `CategoriesView` and `SearchView`.
6. Verify all package tests, app tests, lint, and manual playback on the tvOS simulator.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVDomain SampleTVAPI SampleTVPersistence SampleTVDiscovery SampleTVSearch SampleTVPlayer SampleTVPlaybackProgress; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```

## Definition of done

- All feature and trailer resources in `CatalogPlaybackResourceResolver` load and play without HTTP `403` errors on the tvOS simulator.
- Intentional playback errors in `PlayerView` display an opaque error view with focusable **Try Again** and **Close** controls instead of a blank screen.
- *New Releases* returns released titles (`<= today`) and *Top Rated* excludes low-vote noise (`vote_count >= 100`).
- *Continue Watching* only shows items matching the active profile and selected `Movies` / `TV Shows` filter, and opening/closing a stream under 5 seconds does not add a zero-progress item.
- `CategoriesView` and `SearchView` offer retryable error UI on failure.
- All unit tests and `swiftlint lint --strict` pass with 0 errors.

**Next:** [Phase 16: Design System, `SampleTVUI` Overhaul & Image Caching](../../Phase16_Design_System_And_Cards/Documentation/Phase_16_Design_System_And_Cards.md)
