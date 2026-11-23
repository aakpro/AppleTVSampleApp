# SampleTV

A tvOS streaming-style sample app (inspired by Apple TV+) built to demonstrate Clean Architecture with
SwiftUI and local Swift packages. It lists movies and TV shows from [TMDB](https://www.themoviedb.org),
supports search and filtering, and plays a sample HLS stream with the system player.

> **Status: Phase 1 not started.** The repository currently holds the Xcode tvOS template
> (SwiftUI + SwiftData) and the planning documents. Everything below describes the *target* design;
> [Docs/PROJECT_STRUCTURE.md](Docs/PROJECT_STRUCTURE.md) tracks what actually exists.

## Requirements

| Tool | Version | Notes |
|------|---------|-------|
| Xcode | 27.2 | The project's tvOS deployment target is 27.2, so older Xcodes cannot build it |
| Swift | 6.x toolchain | Language mode is still Swift 5 in the template; Phase 1 moves it to Swift 6 |
| SwiftLint | 0.65+ | `brew install swiftlint` |
| TMDB account | free | For an *API Read Access Token* (see below) |

## Quick start

```bash
git clone git@github.com:aakpro/AppleTVSampleApp.git && cd AppleTVSampleApp
open SampleTV.xcodeproj           # scheme: SampleTV, run on any Apple TV simulator
```

TMDB token (available once Phase 1 has landed the `Config/` folder):

1. Create a free account at themoviedb.org, then **Settings → API → API Read Access Token**.
2. `cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig` and paste the token. This file is git-ignored.
3. Without a token the app still launches and shows a "token missing" screen.

Build and test from the command line:

```bash
UDID=$(xcrun simctl list devices available -j \
  | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')

xcodebuild test -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint
```

## Architecture in one page

Dependencies point inward. The Domain knows nothing about TMDB, SwiftUI or AVKit.

```
SampleTV (app target: composition root, navigation, reads the token)
   │ wires together
   ├── SampleTVDiscovery ─┐
   ├── SampleTVSearch    ─┼─► SampleTVUI ─┐
   ├── SampleTVPlayer     │               ├─► SampleTVDomain   (entities, MediaRepository protocol, use cases)
   └── SampleTVAPI ───────┴───────────────┘        ▲
        (TMDB client, DTOs, retry, caching)  ──────┘  implements MediaRepository
```

- **MVVM** in the presentation layer: `@MainActor @Observable` view models, SwiftUI views.
- **Dependency injection** is plain constructor injection from one composition root (`AppContainer`).
  No DI framework.
- **Swift 6 concurrency**: async/await, `Sendable` value types, actors where state is shared. No Combine.
- **Boundaries are enforced** by `Package.swift` (a package cannot import what it does not declare)
  and by SwiftLint custom rules, both checked in CI.

Details: [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md).

## Documentation

| Document | Purpose |
|----------|---------|
| [AGENTS.md](AGENTS.md) | Instructions for AI coding agents working in this repo |
| [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) | Layers, modules, DI, concurrency, testing |
| [Docs/API_SPECS.md](Docs/API_SPECS.md) | TMDB endpoints, auth, errors, retry, caching |
| [Docs/PROJECT_STRUCTURE.md](Docs/PROJECT_STRUCTURE.md) | Target file tree, per-phase deliverables, progress |
| [Docs/RELEASE_PROCESS.md](Docs/RELEASE_PROCESS.md) | Branching, CI gates, versioning, releases |
| [Docs/PR_TEMPLATE.md](Docs/PR_TEMPLATE.md) | Pull request template and review checklist |
| `Docs/Phase0X_*/Documentation/` | One implementation guide per phase |
| `Docs/templates/` | Verified config templates (SwiftLint, CI, xcconfig, .gitignore) |

## Roadmap

Domain comes before the API layer because the API layer implements a protocol the Domain defines.

| Phase | Scope | Branch |
|-------|-------|--------|
| 1 | Foundation: remove template code, Swift 6, config/secrets, `AppContainer`, lint, CI | `feature/phase_01_foundation` |
| 2 | `SampleTVDomain`: entities, `MediaRepository` port, use cases | `feature/phase_02_domain_layer` |
| 3 | `SampleTVAPI`: TMDB client, DTO mapping, retry, caching | `feature/phase_03_api_layer` |
| 4 | `SampleTVUI` + `SampleTVDiscovery`: browse grid, details screen | `feature/phase_04_movie_discovery` |
| 5 | `SampleTVSearch`: debounced search, filters, pagination | `feature/phase_05_search_module` |
| 6 | `SampleTVPlayer`: AVKit playback of a sample HLS stream | `feature/phase_06_player_feature` |

## Decisions on earlier open questions

| Question | Decision |
|----------|----------|
| Should use cases carry UX concerns such as rate limiting? | No. Use cases hold business rules only (e.g. minimum search length). Rate limiting and retry are transport concerns in `SampleTVAPI`. |
| How much offline support? | None beyond HTTP caching (`URLCache`). Offline shows an error state with a retry action. |
| TMDB API v4? | Not needed. v3 endpoints are authenticated with the v4 *Read Access Token* as a Bearer header. |
| Per-module tests or shared framework? | Each package has its own test target (Swift Testing). No shared test framework until duplication hurts. |
| Where does video come from? | TMDB has no streams. Playback uses a public sample HLS URL (Phase 6). |

## TMDB attribution

This product uses the TMDB API but is not endorsed or certified by TMDB. TMDB's terms require showing
that notice (and their logo) in the app; the Phase 4 about/footer view includes it. TMDB's free API tier is
for non-commercial use.
