# Phase 10: Categories & Multi-Shelf Discovery

| | |
|---|---|
| Branch | `feature/phase_10_categories` |
| Depends on | Phase 9 |
| Delivers | Genre/category shelves on Discover, a dedicated Categories browse view, progress overlay on `MediaCard`, and category/kind filter controls in `SampleTVSearch` |

## Deliverables

```text
Packages/SampleTVDomain/Sources/SampleTVDomain/
└── Categories.swift                   MediaShelf, GetGenres, GetDiscoveryShelves

Packages/SampleTVUI/Sources/SampleTVUI/
├── MediaCard.swift                    optional playback progress bar overlay
└── CategoryTile.swift                 focusable tvOS category card

Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
├── DiscoveryView.swift                Movies/TV switcher + horizontal shelves
├── DiscoveryViewModel.swift           concurrent shelf loading via withTaskGroup
├── CategoriesView.swift               Movie & TV genre directory
└── CategoryResultsView.swift          paginated filtered grid + sort picker

Packages/SampleTVSearch/Sources/SampleTVSearch/
└── SearchView.swift                   media kind + genre filter controls

SampleTV/RootView.swift                Discover, Categories, Search, Profile tabs
```

## Design

- **Reuse existing TMDB contracts:** `MediaRepository.genres(for:)` (`/genre/{kind}/list`) and `MediaRepository.discover(_:page:)` already exist in Domain and `SampleTVAPI` — no new network endpoints are required.
- **Concurrent shelf loading:** `DiscoveryViewModel` loads curated shelves (*Popular*, *Top Rated*, *New Releases*) and top genres concurrently using `withTaskGroup`, keeping individual shelf failures isolated.
- **Search filtering:** Expose `MediaFilter` controls (`All` / `Movies` / `TV Shows` and genres) in `SearchView` using the existing `MediaFilter.matches(_:)` client-side filter.

## Steps

1. Branch `feature/phase_10_categories` from `main`.
2. Add `MediaShelf`, `GetGenres`, and `GetDiscoveryShelves` to `SampleTVDomain` + unit tests.
3. Add `CategoryTile` and `MediaCard` progress bar support in `SampleTVUI`.
4. Upgrade `DiscoveryView`/`DiscoveryViewModel` to horizontal shelves, add `CategoriesView` + `CategoryResultsView`, and expose filters in `SearchView`.
5. Add the **Categories** tab in `RootView`.

## Verification

- `xcodebuild test` passes for `SampleTVDomain`, `SampleTVUI`, `SampleTVDiscovery`, `SampleTVSearch`, and `SampleTV`.
- `swiftlint lint` passes with 0 errors.

## Definition of done

- Users can switch between Movies and TV Shows, browse horizontal category shelves, open a full paginated category grid, and filter search results by kind/genre.

**Next:** [Phase 11: Trailers & Free Playable Resources](../../Phase11_Trailers_And_Playback/Documentation/Phase_11_Trailers_And_Playback.md)
