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
