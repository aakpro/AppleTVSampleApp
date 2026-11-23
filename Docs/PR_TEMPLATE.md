# Pull request template and review guide

Phase 1 copies the block below into `.github/pull_request_template.md`, so GitHub pre-fills every PR with it.
Delete sections that do not apply instead of leaving them blank. See [RELEASE_PROCESS.md](RELEASE_PROCESS.md) for the
merge rules.

## Template

````markdown
## Summary
<!-- One or two sentences: what changes and why. Link the phase or issue: "Phase 3 – API layer", Closes #123 -->

## Changes
<!-- Bullet the notable changes. Name the packages/modules touched. -->
-

## Architecture check
- [ ] Dependency direction respected (Domain imports Foundation only; features do not import `SampleTVAPI` or each other)
- [ ] No new third-party dependencies (or each one is justified below)
- [ ] Errors surface as `MediaError`; no raw `URLError` reaches the UI
- [ ] No secrets or tokens in code, tests, fixtures, logs or screenshots

## Testing
- [ ] Unit tests added/updated (Swift Testing); network is stubbed
- [ ] `xcodebuild test` passes for every touched package and for the `SampleTV` scheme
- [ ] `swiftlint lint` has no errors and I added no new warnings
- Coverage of touched code: <!-- from `xccov`, e.g. API 88% (was 85%) -->
- Manually verified on an Apple TV simulator: <!-- what you tried, incl. focus/remote navigation for UI changes -->

## UI changes (delete if none)
<!-- Before/after screenshots or a short screen recording from the tvOS simulator. -->

## Breaking changes
<!-- "None", or describe what breaks and how to migrate (public API of a package, config keys, build settings). -->

## Release notes
<!-- The line for CHANGELOG.md under [Unreleased]. -->
- [ ] `CHANGELOG.md` updated
- [ ] Phase status table in `Docs/PROJECT_STRUCTURE.md` updated (phase PRs only)
````

## Review guide

Reviewers (or the author, during self-review) check, in this order:

1. **Does it build and pass CI?** Do not review style on a red PR.
2. **Architecture.** Imports and dependencies match the module table in
   [ARCHITECTURE.md](ARCHITECTURE.md); Domain stays framework-free; views hold no business logic.
3. **Correctness.** Cancellation handled (`CancellationError` is not an error state), no main-thread blocking, no data
   races (`Sendable`, `@MainActor` view models), pagination stops at `total_pages`, `MediaID` used instead of bare ints.
4. **Tests.** Behaviour is asserted, not just executed; failure paths covered; no real network; no sleeps longer than a
   few milliseconds.
5. **tvOS UX.** Everything reachable by focus, sensible initial focus, nothing relies on touch, content respects safe areas.
6. **Security and privacy.** No tokens in the diff, URLs, logs or screenshots; TMDB attribution still visible.
7. **Docs.** README/Docs/CHANGELOG match the behaviour after this change.

## Reasons a PR is sent back

- CI is red, or the PR disables a lint rule or test to get green.
- A feature package imports `SampleTVAPI` or another feature; the Domain imports anything but Foundation.
- Business logic in a SwiftUI view.
- UI work without screenshots or a note on how it was verified on the simulator.
- Tests that hit the real network, or depend on timing, ordering or machine state.
- A secret, token or personal path committed.
- New dependency without discussion.
- Unrelated changes bundled in; split them.

## Approval and merge

- One approval (see RELEASE_PROCESS.md for the solo-maintainer rule), CI green, branch up to date with `main`.
- Squash-merge on GitHub with a Conventional Commit title, e.g. `feat(api): add TMDB client with retry (#7)`.
