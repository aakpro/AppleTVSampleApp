# Phase 16: Design System, `SampleTVUI` Overhaul & Image Caching

| | |
|---|---|
| Branch | `feature/phase_16_design_system_and_cards` |
| Depends on | Phase 15 |
| Delivers | Brand `AccentColor` & `SampleTVUI` theme tokens, cached poster/backdrop image loader with distinct loading and missing-artwork placeholders, fixed-width unclipped `MediaCard`, uniform `CategoryTile` with genre iconography, and unclipped horizontal shelf containers |

## Deliverables

```text
SampleTV/Assets.xcassets/AccentColor.colorset/
└── Contents.json                          configured brand accent color (light/dark tvOS)

Packages/SampleTVUI/Sources/SampleTVUI/
├── Theme.swift                            spacing, card sizes, corner radii, gradient & scrim tokens
├── ImageURLBuilder.swift                  add backdrop sizes (w780, w1280, original) & empty-path guard
├── CachedImageLoader.swift                URLCache-backed image loader
├── PosterImage.swift                      loading shimmer/spinner + title fallback + strict 2:3 fill/clip
├── MediaCard.swift                        fixed-width 2:3 poster card, unclipped footer, high-contrast progress bar
├── CategoryTile.swift                     uniform tile size, padded layout, genre icons & subtle gradients
└── MediaShelfRow.swift                    horizontal ScrollView with tvOS 17 .contentMargins & .scrollClipDisabled
```

## Design

- **Brand palette & `AccentColor`:** Populate `SampleTV/Assets.xcassets/AccentColor.colorset/Contents.json` so `.tint` and `.accentColor` across buttons, progress bars, toggles, and pickers reflect a cohesive cinema palette instead of fallback system colors. Centralize card widths (`posterWidth = 220`, `gridPosterWidth = 230`, `tileSize = 280 × 150`), corner radii, and dark scrims in `Theme.swift`.
- **Cached image loading & missing-poster polish:**
  - `ImageURLBuilder.url(for:size:)` returns `nil` for empty/whitespace paths in addition to `nil`, and adds `.w780`, `.w1280`, and `.original` sizes for hero/detail banners.
  - Replace uncached `AsyncImage` inside `PosterImage` with `CachedImageLoader` (using a shared `URLSession` with dedicated image `URLCache`) so scrolling shelves does not flash grey boxes on cached posters.
  - Clearly separate **loading** (dark neutral surface with subtle `ProgressView` / pulse) from **missing or failed artwork** (rich subtle gradient with icon + fallback title text inside the `2:3` poster frame).
  - Enforce strict `.aspectRatio(2 / 3, contentMode: .fill)` + `.clipped()` + uniform corner radius so odd-ratio TMDB images never pillarbox or stretch.
- **Fix `MediaCard` layout, borders, and text clipping:**
  - Constrain `MediaCard` to an explicit width (`220pt` default) so long titles (*The Hunger Games: Sunrise on the Reaping*, *The Port Macquarie Ripper*) truncate cleanly with `…` instead of stretching the card platter into a wide grey slab next to the poster.
  - Remove text clipping on focus by keeping **only the poster (plus progress bar)** inside `.buttonStyle(.card)` and rendering the title (`.lineLimit(1)`) and fixed-height subtitle row (`releaseYear` or rating, always reserving vertical space even when `year == nil`) **below** the poster card — eliminating `"ron Man"` / `"low Horses"` focus-zoom clipping and uneven row heights.
  - Wrap the bottom `playbackProgress` bar inside a dark translucent pill/scrim track with accent fill so progress reads crisply over both light and dark posters.
- **Uniform `CategoryTile`:** Lock `CategoryTile` to a uniform `280 × 150` frame with generous inner padding (`20pt`) so titles never touch card edges and rows don't look jagged (*Crime* vs. *Action & Adventure*). Add a genre/kind icon and subtle tonal gradient mapping instead of repeating `film.stack` on every tile.
- **Unclipped horizontal focus scrolling:** Create `MediaShelfRow` in `SampleTVUI` using `ScrollView(.horizontal, showsIndicators: false)` with tvOS 17.0-compatible `.contentMargins(.horizontal, 60)` / `.contentMargins(.vertical, 24)` and `.scrollClipDisabled()` so focused cards at the leading edge or top/bottom never get chopped flat by scroll bounds. Adopt `MediaShelfRow` in `DiscoveryView`, `DetailsView`, `CategoriesView`, and `ProfileView`.

## Steps

1. Branch `feature/phase_16_design_system_and_cards` from `main`.
2. Configure `AccentColor.colorset` and create `Theme.swift` in `SampleTVUI`.
3. Extend `ImageURLBuilder` (empty-string guard + backdrop sizes) and implement `CachedImageLoader` + updated `PosterImage` with distinct loading and missing-title fallback states.
4. Refactor `MediaCard`, `CategoryTile`, and add `MediaShelfRow` in `SampleTVUI`.
5. Adopt `MediaShelfRow` and updated `MediaCard` / `CategoryTile` parameters across `DiscoveryView`, `DetailsView`, `CategoriesView`, `CategoryResultsView`, `SearchView`, and `WatchlistSection` in `ProfileView`.
6. Update/add `SampleTVUITests` unit tests for `ImageURLBuilder`, `MediaCard`, and `CategoryTile`, and visually verify card scaling and unclipped focus on the simulator.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVUI SampleTVDiscovery SampleTVSearch SampleTVProfile; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```

## Definition of done

- No card stretches horizontally beyond its `2:3` poster width for long titles, and no card titles or years clip against `.card` borders when focused or unfocused.
- Cards without `releaseYear` align cleanly at the exact same height as neighboring cards.
- Horizontal shelves (`MediaShelfRow`) do not crop rounded corners on the leading/top/bottom edges during Siri Remote focus lift.
- Missing/failed posters show a legible styled fallback with the title; loading posters show a distinct loading state and stay cached across scrolls.
- `CategoryTile` tiles share uniform dimensions, padded typography, and distinct genre/kind icons.
- `AccentColor` is configured and progress bars on *Continue Watching* cards are clearly visible over bright or dark artwork.
- All tests and `swiftlint lint --strict` pass with 0 errors.

**Next:** [Phase 17: Discover, Categories & Search Layout Redesign](../../Phase17_Discover_Search_Chrome/Documentation/Phase_17_Discover_Search_Chrome.md)
