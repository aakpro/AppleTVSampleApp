# Phase 20: TV Show Season & Episode Selection

| | |
|---|---|
| Branch | `feature/phase_20_tv_seasons_episodes` |
| Depends on | Phase 19 |
| Delivers | Domain season/episode entities & use case, TMDB season/episodes API mapping, episode-aware playback resolution & SwiftData progress persistence, tvOS season switcher & 16:9 episode card shelf, and unit + UI test coverage |

## Deliverables

```text
Packages/SampleTVDomain/
├── Sources/SampleTVDomain/Media/TVSeason.swift
├── Sources/SampleTVDomain/Media/TVEpisode.swift
├── Sources/SampleTVDomain/Media/TVSeasonDetails.swift
└── Tests/SampleTVDomainTests/TVSeasonTests.swift

Packages/SampleTVAPI/
├── Sources/SampleTVAPI/DTOs/TVSeasonDTO.swift
└── Tests/SampleTVAPITests/TVSeasonDecodingTests.swift

Packages/SampleTVDiscovery/
├── Sources/SampleTVDiscovery/EpisodeCard.swift
├── Sources/SampleTVDiscovery/SeasonsEpisodesSection.swift
└── Tests/SampleTVDiscoveryTests/TVSeasonsDetailsViewModelTests.swift

SampleTVTests/TVPlaybackNavigationTests.swift
SampleTVUITests/SampleTVUITests.swift
```

## Design

- **Domain & API:** `TVSeason`, `TVEpisode`, and `TVSeasonDetails` extend `MediaDetails.seasons` and `MediaRepository.seasonDetails(of:seasonNumber:)` backed by `GetTVSeasonDetails`. `DetailsDTO` maps normalized regular seasons ahead of non-empty Specials (`season_number == 0`), and `TMDBMediaRepository` fetches `/tv/{id}/season/{season_number}`.
- **Playback & Progress:** `PlaybackResourceResolver` and `ResolvePlaybackResources` accept optional `episode: TVEpisode?` context so `CatalogPlaybackResourceResolver` varies streams and formats `"S<season> E<episode> · <episode name>"` subtitles. `PlaybackProgress` and SwiftData `StoredProgress` persist optional `seasonNumber` and `episodeNumber` for resuming the right episode.
- **tvOS UI:** `DetailsViewModel` auto-selects the saved or first regular season, caches fetched seasons, supports retry recovery, and resolves episode playback. `SeasonsEpisodesSection` renders focusable season pills with active `AccentColor` highlight and a horizontal unclipped strip of 16:9 `EpisodeCard`s (`w500` stills, external titles, metadata, and synopses).

## Definition of done

- All 10 local Swift package test suites, `SampleTVTests`, and `SampleTVUITests` (including `testTVShowSeasonAndEpisodeSelectionIfLoaded`) pass on the Apple TV simulator.
- `swiftlint lint --strict` passes with 0 errors and 0 warnings across all Swift files.
- Verified on the 1080p Apple TV simulator across TV Show Details, active season styling, season switching, and episode focus cards.
