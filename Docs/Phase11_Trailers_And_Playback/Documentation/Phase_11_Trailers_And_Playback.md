# Phase 11: Trailers, Free Playable Resources & Rich Details

| | |
|---|---|
| Branch | `feature/phase_11_trailers_and_playback` |
| Depends on | Phase 10 |
| Delivers | TMDB `/videos` decoding, `PlaybackResourceResolver` mapping titles/genres to distinct public HLS/MP4 streams, **Play** / **Resume** / **Watch Trailer** CTAs, Recommendations on `DetailsView`, and player metadata |

> [!IMPORTANT]
> TMDB's `/videos` endpoint returns YouTube/Vimeo keys (`site: "YouTube"`, `key: "..."`), which `AVPlayer` cannot stream directly. Never pass a `youtube.com` webpage URL to `AVPlayer`.

## Deliverables

```text
Packages/SampleTVDomain/Sources/SampleTVDomain/
├── Entities.swift                     MediaVideo, VideoKind, MediaDetails.videos
└── PlaybackResource.swift             PlayableResource, PlaybackResourceKind, PlaybackResourceResolver

Packages/SampleTVAPI/Sources/SampleTVAPI/
├── DTOs.swift                         VideoDTO, VideosResponseDTO (append_to_response=recommendations,videos)
└── CatalogPlaybackResourceResolver.swift

Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
├── DetailsView.swift                  Play/Resume CTA, Watch Trailer CTA, More Like This row
└── DetailsViewModel.swift             resume label + resolved playable resources

Packages/SampleTVPlayer/Sources/SampleTVPlayer/
└── PlayerView.swift                   optional title/subtitle AVPlayerItem externalMetadata
```

## Design

- **Single round-trip metadata:** Update `TMDBMediaRepository.details(of:)` to request `append_to_response=recommendations,videos`.
- **Distinct playable streams:** `CatalogPlaybackResourceResolver` deterministically maps each `MediaID` / primary genre to a curated catalog of verified public-domain / Creative Commons HLS & MP4 streams (e.g., Apple test streams, Blender Open Movies *Big Buck Bunny*, *Sintel*, *Tears of Steel*, *Elephants Dream*) for both main features and trailers, pairing them with TMDB's official trailer name and external reference URL.
- **No trailer progress pollution:** `PlayableResource.trackProgress` is `true` for `.feature` and `false` for `.trailer` so watching a trailer never overwrites Continue Watching.
- **Recommendations UI:** Render `MediaDetails.recommendations` as a focusable horizontal **"More Like This"** shelf on `DetailsView`.

## Verification

- `xcodebuild test` passes for `SampleTVDomain`, `SampleTVAPI`, `SampleTVDiscovery`, and `SampleTV`.
- `swiftlint lint` passes with 0 errors.

## Definition of done

- `DetailsView` shows **Play** (or **Resume MM:SS**), **Watch Trailer**, and **More Like This**.
- Different titles/genres play distinct verified streams in `PlayerView` with title metadata in the tvOS info panel.

**Next:** [Phase 12: Watchlist, UI Tests & Release v2.0](../../Phase12_Watchlist_And_Release/Documentation/Phase_12_Watchlist_And_Release.md)
