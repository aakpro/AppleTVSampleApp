# Phase 17: Discover, Categories & Search Layout Redesign

| | |
|---|---|
| Branch | `feature/phase_17_discover_search_chrome` |
| Depends on | Phase 16 |
| Delivers | Un-truncated pickers & header layout across Discover/Categories/Search, Featured Hero Banner on Discover, denser 5–6 card shelves with deduplicated genres, proper CategoryResults header/pagination indicator, and Search loading/idle polish |

## Deliverables

```text
Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
├── DiscoveryView.swift                inline header switcher (no floating mid-screen pill), Hero Banner, denser shelves
├── DiscoveryViewModel.swift           featuredHero selection + shelf deduplication helper
├── CategoriesView.swift               explicit top header (no colliding centered navigationTitle), genre icons
└── CategoryResultsView.swift          aligned top header + sort picker, bottom pagination spinner, consistent grid spacing

Packages/SampleTVSearch/Sources/SampleTVSearch/
├── SearchViewModel.swift              add .loading state
└── SearchView.swift                   un-truncated 3-segment picker, loading indicator, polished idle/empty states
```

## Design

- **Remove floating colliding toolbars & truncated pickers:**
  - In `DiscoveryView`, remove `ToolbarItem(placement: .principal)` and `.frame(width: 260)` — that caused `[ Movies | TV Sh... ]` to truncate `"TV Shows"` and float transparently right over scrolled movie posters while hiding `.navigationTitle("Discover")`. Place a left-aligned **Discover** header with an unconstrained `.fixedSize()` **Movies | TV Shows** segmented picker inside the scrollable top header above the Hero Banner so it scrolls naturally out of the way.
  - In `SearchView`, remove `.frame(maxWidth: 420)` on the `All | Movies | TV Shows` picker so `"TV Shows"` never truncates to `"TV Sho..."`.
  - In `CategoriesView` and `CategoryResultsView`, replace the dim floating centered `.navigationTitle` (which sits awkwardly mid-top over empty space) with explicit, clean tvOS top headers aligned to the `60pt` safe-area grid (and well-spaced sort controls in `CategoryResultsView`).
- **Featured Hero Banner (`DiscoveryView`):**
  - Showcase the top featured item from *Popular* at the top of `DiscoveryView` (`height ~ 440pt` so the *Continue Watching* / *Popular* shelf peeks cleanly above the fold on 1080p): full-width `backdropPath` (`w1280`) with a left/bottom dark gradient scrim, title, year/rating metadata, short 2–3 line overview, and focusable **Play** / **Details** buttons.
  - Ensure `DiscoveryViewModel` keeps shelves balanced (5–6 `220pt` cards visible per row) and avoids echoing the same top movies verbatim across consecutive genre shelves when possible.
- **Search UX polish (`SearchView` & `SearchViewModel`):**
  - Add `.loading` to `SearchViewModel.State` (`idle | loading | loaded([MediaItem]) | failed(MediaError)`) so typing or changing filters shows a clear loading spinner instead of stale idle copy during the debounce + API request.
  - Keep the idle state clean (hide or soften the genre filter when no search is active, or show concise search tips) and ensure grid card widths match `MediaCard`'s `220–230pt` sizing with proper `.contentMargins` so focus lift never clips.
- **CategoryResults pagination feedback:** Show a subtle bottom `ProgressView` when `CategoryResultsViewModel` fetches `loadNextPage()`, and keep grid columns aligned (`GridItem(.adaptive(minimum: 220, maximum: 240), spacing: 40)`).

## Steps

1. Branch `feature/phase_17_discover_search_chrome` from `main`.
2. Update `DiscoveryViewModel` to expose `featuredItem` (derived from loaded shelves) and reduce duplicate items across top shelves; update `DiscoveryView` with the inline header switcher, Featured Hero Banner, and `MediaShelfRow` shelves.
3. Update `CategoriesView` (distinct genre icons + explicit header) and `CategoryResultsView` (clean header + sort bar + pagination indicator).
4. Add `.loading` to `SearchViewModel.State` and update `SearchView` (`All | Movies | TV Shows` without truncation, loading spinner, refined idle/results grid spacing).
5. Update unit tests in `SampleTVDiscoveryTests` and `SampleTVSearchTests`, run all tests + lint, and inspect all three tabs on the tvOS simulator.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVUI SampleTVDiscovery SampleTVSearch; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```

## Definition of done

- Neither `DiscoveryView` nor `SearchView` truncates `"TV Shows"` in segmented pickers, and no toolbar pill floats over scrolled posters.
- `DiscoveryView` shows a Featured Hero Banner plus the first shelf clearly visible above the fold on 1080p.
- `CategoriesView` and `CategoryResultsView` headers align cleanly with the `60pt` layout margin with zero dim centered `.navigationTitle` overlaps.
- `SearchView` displays a loading indicator during search requests and unclipped grid cards on focus.
- All unit tests and `swiftlint lint --strict` pass with 0 errors.

**Next:** [Phase 18: Cinematic Details Screen, Trailers UX & Onboarding](../../Phase18_Details_Auth_Profile/Documentation/Phase_18_Details_Auth_Profile.md)
