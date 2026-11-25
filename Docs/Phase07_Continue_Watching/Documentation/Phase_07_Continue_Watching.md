# Phase 7: Continue Watching & Playback Progress

| | |
|---|---|
| Branch | `feature/phase_07_continue_watching` (merged in PR #8) |
| Depends on | Phase 6 (`SampleTVPlayer`) |
| Delivers | `SampleTVPlaybackProgress`, resume position persistence, and the "Continue Watching" shelf on Discover |

## Deliverables

```text
Packages/SampleTVPlaybackProgress/
├── Package.swift
├── Sources/SampleTVPlaybackProgress/
│   └── UserDefaultsPlaybackProgressStore.swift
└── Tests/SampleTVPlaybackProgressTests/
    └── PlaybackProgressTests.swift

SampleTV/AppContainer.swift            progressStore injection
SampleTV/RootView.swift                PlayerScreen resume & save wiring
```

## Design

- **Progress contract in Domain (`PlaybackProgress`, `PlaybackProgressStore`):** Moved to `SampleTVDomain` during Phase 7b so `SampleTVDiscovery` never imports `SampleTVPlaybackProgress`.
- **Watched threshold:** `PlaybackProgress.isWatched` returns `true` when `position / duration >= 0.9` so finished items drop out of Continue Watching.
- **Player decoupling:** `PlayerView` accepts `initialPosition: TimeInterval?` and `onProgress: (@MainActor @Sendable (TimeInterval, TimeInterval) -> Void)?` without knowing about `SampleTVDomain`.

## Verification

- `xcodebuild test` for `SampleTVPlaybackProgress` and `SampleTVDiscovery`
- `swiftlint lint`

## Definition of done

- Resume position is saved periodically and on disappear, and loaded before starting playback.
- Unfinished items appear in the Continue Watching shelf on `DiscoveryView`.

**Next:** [Phase 7b: Stabilization](Phase_07b_Stabilization.md)
