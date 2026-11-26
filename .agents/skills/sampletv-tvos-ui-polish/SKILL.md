---
name: sampletv-tvos-ui-polish
description: >-
  Guides tvOS 17 SwiftUI layout, focus ergonomics, card/image rendering, playback
  error recovery, and simulator screenshot verification in SampleTV. Use when
  creating, modifying, or reviewing any SampleTV SwiftUI view, card, modal,
  player overlay, or UI test.
---

# SampleTV tvOS 17 UI & Visual QA

Use this skill whenever designing, implementing, or reviewing tvOS UI views, cards, navigation chrome, or playback overlays in SampleTV.

## Deployment Target Constraints

- All packages and app targets deploy to **tvOS 17.0**. Do **not** use tvOS 18+ APIs such as `Tab(...)` or `role: .search`; use `.tabItem` and tvOS 17 `.searchable`.
- Use tvOS 17.0-supported `.contentMargins(...)` and `.scrollClipDisabled()` for focusable shelf scrolling.

## Layout, Focus & Component Rules

1. **Fixed card & tile dimensions:**
   - Lock `MediaCard` to an explicit width (`220pt` in shelves, `220–240pt` in grids) so long movie titles truncate cleanly instead of stretching `.card` platters wider than the `2:3` poster.
   - Reserve uniform vertical footer height (`title` + fixed-height `year`/metadata line) even when `releaseYear` is `nil` so adjacent cards align across rows.
   - Lock `CategoryTile` to uniform dimensions (`280 × 150`) with internal padding and distinct genre/kind SF Symbols rather than text-sized uneven boxes.
2. **Never clip text or focus borders:**
   - Place **only the poster (plus progress scrim)** inside `.buttonStyle(.card)`, and render titles/subtitles cleanly below the poster so tvOS focus zoom/parallax never slices off leading characters or bottom years.
   - For `.bordered` / `.borderedProminent` / `.card` action buttons (`DetailsView`, `ProfileView`, `LoginView`), always include explicit internal padding and `Label` icons.
   - Give horizontal `ScrollView` shelves `.contentMargins(.horizontal, 60)`, `.contentMargins(.vertical, 24)`, and `.scrollClipDisabled()` so leading/top/bottom focus lifts never get chopped flat.
3. **Opaque covers & legible contrast:**
   - Always give `.fullScreenCover` destinations (`DetailsView`, `PlayerView` error overlays) an opaque backdrop (e.g., blurred/vignetted `backdropPath` or dark solid surface) so the underlying `TabView` never bleeds through.
   - Never rely on an unconfigured `AccentColor`; set explicit brand tokens in `SampleTVUI/Theme.swift` and `AccentColor.colorset`. Wrap card progress bars in a dark translucent track scrim.
4. **No truncated pickers or floating title collisions:**
   - Never hardcode narrow widths (`width: 260`, `maxWidth: 420`) on segmented `Picker`s (`Movies | TV Shows`, `All | Movies | TV Shows`); size dynamically so `"TV Shows"` never truncates.
   - Avoid `.principal` toolbar overlays that float directly over scrolled posters, and replace colliding centered `.navigationTitle` headers on `ScrollView` tabs with explicit aligned top headers.
5. **Images & TMDB data hygiene:**
   - Use `URLCache`-backed image loading with `.aspectRatio(2 / 3, contentMode: .fill).clipped()`.
   - Distinguish loading state (shimmer/spinner) from missing/failed artwork (styled gradient + title text inside the poster frame).
   - Ensure *New Releases* clamps release dates to `<= today` and *Top Rated* enforces a minimum `vote_count` threshold so shelves aren't filled with unreleased 2030+ placeholders or 1-vote noise.
6. **Playback & Continue Watching:**
   - Verify stream/trailer URLs return HTTP `200` (no `403` dead links), observe `AVPlayerItem` failure states reliably so `PlayerView` shows an opaque **Close + Try Again** error screen, and ignore progress updates under 5 seconds.
   - Scope *Continue Watching* to the active `MediaKind` and `ViewerProfile`.

## Simulator Visual Verification Workflow

Before finishing any UI change, build, install, launch on an Apple TV simulator, navigate affected screens, and inspect screenshots directly:

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
xcrun simctl boot "$UDID" 2>/dev/null || true
xcodebuild build -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -derivedDataPath /tmp/SampleTVDerivedData
xcrun simctl install "$UDID" /tmp/SampleTVDerivedData/Build/Products/Debug-appletvsimulator/SampleTV.app
xcrun simctl launch "$UDID" sample.SampleTV
xcrun simctl io "$UDID" screenshot /tmp/screen.png
```
