# AGENTS.md

Instructions for AI coding agents (and a quick orientation for humans) working in this repository.
Read [README.md](README.md) first for the product and [Docs/ARCHITECTURE.md](Docs/ARCHITECTURE.md) for the design.

## Project snapshot

- tvOS app, SwiftUI, open `SampleTV.xcworkspace` (single entry; wraps `SampleTV.xcodeproj` and `Packages/*`), scheme `SampleTV`
  (targets: `SampleTV`, `SampleTVTests`, `SampleTVUITests`).
- Features live in **local Swift packages** under `Packages/` (created phase by phase).
- Data comes from the TMDB v3 REST API. Video is a public sample HLS stream.
- **Current state:** Phases 1, 2, 3, and 3b (Stabilization) are complete and verified green. `SampleTVDomain` and `SampleTVAPI` packages build, pass unit tests, and are linked to the `SampleTV` app target in `SampleTV.xcworkspace`. Next up is **Phase 4: Movie discovery (`SampleTVUI`, `SampleTVDiscovery`)**. See [Docs/PROJECT_STRUCTURE.md](Docs/PROJECT_STRUCTURE.md).

## Commands

Resolve a simulator once, then reuse it:

```bash
UDID=$(xcrun simctl list devices available -j \
  | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
```

| Task | Command |
|------|---------|
| Build app | `xcodebuild build -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID"` |
| Test app | `xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests` |
| Test one package | `cd Packages/SampleTVDomain && xcodebuild test -scheme SampleTVDomain -destination "id=$UDID"` |
| Lint | `swiftlint lint` (CI fails on errors; fix warnings you introduce) |
| Coverage | add `-enableCodeCoverage YES -resultBundlePath build/X.xcresult`, then `xcrun xccov view --report --only-targets build/X.xcresult` |

`swift build` / `swift test` do **not** work for these packages: they target tvOS, not macOS. Always go
through `xcodebuild` with a tvOS simulator destination.

## Architecture rules (hard constraints)

1. **Dependency direction.** `SampleTVDomain` imports Foundation only. `SampleTVAPI` and the feature
   packages depend on `SampleTVDomain`. Feature packages never import `SampleTVAPI` or each other.
   Only the app target sees every package.
2. **Ports and adapters.** The Domain defines `MediaRepository`; `SampleTVAPI` implements it. Views and
   view models depend on the protocol (or on use cases), never on `TMDBClient`.
3. **DTOs stay in `SampleTVAPI`.** Map to Domain entities at the boundary. Domain types never carry
   `CodingKeys` for TMDB's snake_case.
4. **DI = constructor injection** from `AppContainer` in the app target. Do not add a DI/service-locator library.
5. **Concurrency.** Swift 6 language mode. View models are `@MainActor @Observable final class`. Models are
   `Sendable` value types. Use `async/await`; do not introduce Combine or completion handlers.
6. **Errors.** The data layer maps everything to `MediaError`. Never surface raw `URLError` to the UI.
   Let `CancellationError` propagate and ignore it in view models.
7. **Identity.** TMDB movie and TV ids collide. Always use `MediaID(kind:value:)`, never a bare `Int`.
8. These rules are enforced by `Package.swift` dependency lists plus the custom rules in `.swiftlint.yml`.
   Do not weaken either to make a change compile; restructure the code instead.

## Conventions

- Tests: **Swift Testing** (`import Testing`, `@Test`, `#expect`) for unit tests; XCTest only for UI tests.
  Stub the network with a fake `HTTPTransport`; unit tests must never hit the real network.
- Target coverage: ≥ 85% for Domain, API and view models. Views are covered by previews and a UI smoke test.
- tvOS UI: use focusable controls (`Button` with `.buttonStyle(.card)` or `.plain`), keep content inside the
  safe area, and test navigation with the Siri Remote model (focus, not touch). tvOS has no volume or brightness
  UI for apps; the system player already provides transport controls.
- Commits: [Conventional Commits](https://www.conventionalcommits.org) with the package as scope,
  e.g. `feat(api): retry on 429 using Retry-After`. One logical change per commit.
- Branches: `feature/phase_0X_<name>` (see the phase table in the README). Never commit directly to `main`.
- Code style: SwiftLint is the source of truth. Prefer small files with one primary type.

## Secrets

- The TMDB token lives in `Config/Secrets.xcconfig` (git-ignored) and reaches the app through an
  `Info.plist` value. **Never** print, log, commit or paste a token, and never hard-code one in tests.
- Do not read or write `Config/Secrets.xcconfig` unless the user asks. Use `Config/Secrets.xcconfig.example` as the reference.
- Live-API tests are opt-in (environment variable `TMDB_READ_ACCESS_TOKEN`) and skipped by default.

## Working on a phase

1. Read `Docs/Phase0X_*/Documentation/Phase_0X_*.md`. It lists deliverables, verified reference code,
   and a definition of done.
2. Confirm the previous phase's definition of done is met (see the status table in `Docs/PROJECT_STRUCTURE.md`).
3. Create the branch, implement in small commits, keep tests green as you go.
4. Before opening a PR: build, test, lint, and tick every box in [Docs/PR_TEMPLATE.md](Docs/PR_TEMPLATE.md).
5. Update the status table in `Docs/PROJECT_STRUCTURE.md` and add a `CHANGELOG.md` entry.

Do **not** mark a phase complete, merge, tag, or push unless the user asked for it.

## Xcode project and workspace caveats

- **Never hand-edit `project.pbxproj`.** Link a local package to the app target with
  `ruby Scripts/link_package.rb <PackageName>` (idempotent, uses the `xcodeproj` gem). Build settings and
  Info.plist keys not covered by a script are a human task: stop and report instead of editing the file.
- **Local package registration in workspace:** `SampleTV.xcworkspace` wraps `SampleTV.xcodeproj`, `Packages/`,
  `Config/`, `Docs/`, `Scripts/`, and root documentation. When creating a new package under `Packages/`,
  add a `<FileRef location="group:<PackageName>">` entry inside `<Group location="container:Packages" name="Packages">`
  in `SampleTV.xcworkspace/contents.xcworkspacedata`, then link it to the app target with `ruby Scripts/link_package.rb <PackageName>`.
- New source files placed inside the `SampleTV/` folder are picked up automatically only if the target uses
  folder-based membership. Verify with a build after adding files.

## Pitfalls worth remembering

- `search/*` endpoints cannot filter by genre, rating or year range (except a single `year`); filter results
  client-side with `MediaFilter.matches(_:)`, and use `discover/*` for server-side filtering.
- `search/multi` also returns people; drop anything whose `media_type` is not `movie` or `tv`.
- TMDB paginates up to 500 pages; stop at `total_pages`.
- Poster/backdrop fields are *paths*; the full URL is built with `ImageURLBuilder` (e.g. `…/t/p/w342/<path>`).
- TMDB's video endpoint returns YouTube/Vimeo keys, which `AVPlayer` cannot play. Do not wire it to the player.
