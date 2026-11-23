# Architecture

How SampleTV is structured and why. Code in this document and in the phase guides was compiled and its
tests were run against the tvOS simulator (Swift 6 language mode) before being written down.

## Principles

1. **Domain first.** Business rules and entities have no dependency on frameworks, the network or UI.
2. **Dependencies point inward.** Outer layers depend on inner ones, never the reverse.
3. **Depend on protocols at boundaries.** The Domain owns the interfaces (ports); outer layers implement them.
4. **Composition over inheritance.** Value types and protocols; no base classes.
5. **Errors are values.** Failures are modelled (`MediaError`) and shown to the user; nothing crashes on a bad response.
6. **Swift 6 concurrency.** `Sendable` models, `@MainActor` view models, structured concurrency.

## Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Presentation   SwiftUI views + @Observable view models      │  SampleTVDiscovery, SampleTVSearch,
│                (depends on Domain, UI)                      │  SampleTVPlayer, SampleTVUI
├─────────────────────────────────────────────────────────────┤
│ Domain         entities, use cases, MediaRepository (port)  │  SampleTVDomain  (Foundation only)
├─────────────────────────────────────────────────────────────┤
│ Data           TMDB client, DTOs, mapping, retry, caching   │  SampleTVAPI  (implements the port)
├─────────────────────────────────────────────────────────────┤
│ App            composition root, navigation, configuration  │  SampleTV target
└─────────────────────────────────────────────────────────────┘
```

The Data layer sits *beside* Presentation, not below it: both depend on Domain, neither knows the other.
Only the App layer knows both and connects them.

## Modules

| Package | Depends on | Contains | Phase |
|---------|-----------|----------|-------|
| `SampleTVDomain` | Foundation | `MediaItem`, `MediaID`, `MediaKind`, `Genre`, `MediaDetails`, `ResultPage`, `MediaFilter`, `SearchQuery`, `MediaError`, `MediaRepository`, use cases | 2 |
| `SampleTVAPI` | Domain | `TMDBClient`, `HTTPTransport`, `RetryPolicy`, DTOs, `TMDBMediaRepository` | 3 |
| `SampleTVUI` | Domain | `MediaCard`, `PosterImage`, `ImageURLBuilder`, shared styling | 4 |
| `SampleTVDiscovery` | Domain, UI | `DiscoveryViewModel`/`DiscoveryView`, details screen | 4 |
| `SampleTVSearch` | Domain, UI | `SearchViewModel`/`SearchView`, filter controls | 5 |
| `SampleTVPlayer` | none | `PlayerView` (AVKit) | 6 |
| App target `SampleTV` | all of the above | `AppContainer`, `AppConfiguration`, navigation, token loading | 1+ |

Rules the build enforces:

- A package can only import what its `Package.swift` lists. `SampleTVDomain` lists nothing.
- `.swiftlint.yml` adds custom rules for what SwiftPM cannot express: Domain may import only Foundation;
  feature packages must not import `SampleTVAPI` or each other.
- CI runs both, so a violation fails the pull request.

Navigation between features (for example Discovery → Player) lives in the app target, so feature packages never
need to know about each other.

## Dependency injection

Constructor injection from a single composition root. No DI framework, no service locator.

```swift
// App target (excerpt). It starts in Phase 1 with only the configuration and gains the repository (Phase 3)
// and one factory method per feature. The complete, compiled version is in the Phase 6 guide.
@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    let repository: any MediaRepository

    init(configuration: AppConfiguration, repository: any MediaRepository) {
        self.configuration = configuration
        self.repository = repository
    }

    static func live() -> AppContainer {
        let configuration = AppConfiguration()
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: configuration.tmdbToken),
            transport: URLSession.tmdbCached()
        )
        return AppContainer(configuration: configuration, repository: TMDBMediaRepository(client: client))
    }

    func makeDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(discover: DiscoverMedia(repository: repository))
    }
}
```

Tests and previews build an `AppContainer` (or just a view model) with a stub `MediaRepository`; nothing needs
swizzling or global state. Only the app target imports `SampleTVAPI`.

## Domain model

- `MediaItem` represents both movies and TV shows, distinguished by `MediaID.kind`. One type avoids
  parallel `Movie`/`TVShow` hierarchies for what the UI treats identically.
- `MediaID` is `(kind, value)` because TMDB movie and TV ids are separate namespaces.
- Use cases are small structs wrapping the repository and adding rules the repository should not know, such as
  "search text shorter than 2 characters never reaches the network".
- Pure logic (`SearchQuery` validation, `MediaFilter.matches`) is plain functions on value types, which makes it
  trivial to test exhaustively.

Full code: [Phase 2](Phase02_Domain_Layer/Documentation/Phase_02_Domain_Layer.md).

## Presentation

- View models are `@MainActor @Observable final class`, hold a state enum (`idle | loading | loaded | failed`),
  and expose `async` methods that views call from `.task`.
- Views are driven by state only. SwiftUI's `.task(id:)` cancels and restarts work when the id changes, which
  provides both reloading on filter change and **search debouncing** (a cancellable `Task.sleep`), so no Combine
  pipeline is needed.
- tvOS specifics: focus-driven interaction (`Button` with `.buttonStyle(.card)`), large layouts, safe-area insets,
  no touch. The system player already supplies transport controls, so there is no custom player UI.

## Data layer

- `TMDBClient` builds requests (Bearer auth, `language`), sends them through an injected `HTTPTransport`
  (`URLSession` in production, a stub in tests), maps HTTP status codes to `MediaError`, and retries
  `429` / `5xx` / offline with exponential backoff, honouring `Retry-After`.
- `TMDBMediaRepository` implements `MediaRepository`, translating `MediaFilter`/`SearchQuery` into TMDB
  parameters and DTOs into entities.
- Caching is HTTP-level (`URLCache`), configured on the `URLSession`. See [API_SPECS.md](API_SPECS.md).

## Error model

```
URLError / HTTP status / JSON error  ──►  MediaError  ──►  view model state .failed(MediaError)  ──►  UI message
```

`MediaError` cases: `offline`, `unauthorized`, `notFound`, `rateLimited(retryAfter:)`, `server(statusCode:)`,
`decoding`, `unknown`. View models translate them to user-facing text; `unauthorized` is treated as a
configuration problem (bad token), not something to retry. `CancellationError` is never an error state.

## Testing

| Layer | Approach | Target |
|-------|----------|--------|
| Domain | Plain Swift Testing unit tests, no mocks beyond a stub repository | ≥ 90% |
| Data | Stub `HTTPTransport` returning canned JSON: status mapping, retry, DTO mapping, request shape | ≥ 85% |
| View models | Stub `MediaRepository`; assert state transitions | ≥ 85% |
| Views | `#Preview` with stub data; one UI smoke test (launch, focus a card, open details) | smoke |
| Live API | Opt-in tests that run only when `TMDB_READ_ACCESS_TOKEN` is set | manual |

Coverage is reported in CI (`xccov`) and checked by reviewers; it is not a hard gate.
Run package tests with `xcodebuild test -scheme <Package> -destination "id=$UDID"` (see [AGENTS.md](../AGENTS.md)).

## Out of scope

User accounts, DRM, real catalogue streaming, offline downloads, and an on-disk database. If persistence is
needed later (for example "continue watching"), SwiftData is already available in the template and belongs
behind a Domain protocol like everything else.
