# Phase 19: Visual QA, Accessibility & Release `v2.1.0`

| | |
|---|---|
| Branch | `feature/phase_19_visual_qa_and_release` |
| Depends on | Phase 18 |
| Delivers | Expanded tvOS XCUITest regression suite, ≥ 85% unit-test coverage verification across Domain/API/Persistence/ViewModels, VoiceOver & 10-foot accessibility audit, visual screenshot QA sign-off, and `v2.1.0` release |

## Deliverables

```text
SampleTVUITests/
└── SampleTVUITests.swift                  end-to-end Siri Remote coverage (Discover -> Details -> Watchlist -> Categories -> Search -> Profile)

Packages/*/Tests/
└── *Tests.swift                           regression coverage for Phase 13-18 behaviors

CHANGELOG.md                               [2.1.0] release notes
Docs/PROJECT_STRUCTURE.md                  Phases 13-19 status table updated to Complete & Verified
```

## Design

- **UI regression guardrails (`SampleTVUITests`):** Extend `SampleTVUITests` with deterministic Siri Remote navigation checks verifying:
  - Demo login flow & absence of `LoginView` flash on relaunch when already authenticated.
  - Discover Hero + un-truncated `"TV Shows"` picker toggle.
  - Opening `DetailsView`, toggling **Add to My List** / **In My List**, verifying **Watch Trailer** / **Play** launch cleanly, and navigating *More Like This*.
  - Navigating `Categories` -> `CategoryResultsView` -> `Sort` picker, `Search`, and `Profile` preferences + *My List*.
- **Accessibility & 10-foot legibility pass:**
  - Audit VoiceOver combined labels on `MediaCard` (title, year, watched/progress percentage), `CategoryTile`, and `DetailsView` metadata row.
  - Verify minimum contrast ratios across focused/unfocused buttons, progress bars, and translucent scrims on the 1080p Apple TV simulator.
  - Verify `.accessibilityIdentifier` hooks for automated UI assertions without affecting user-facing VoiceOver strings.
- **Coverage & release discipline:** Measure coverage via `xcrun xccov`, confirm ≥ 85% across `SampleTVDomain`, `SampleTVAPI`, `SampleTVPersistence`, and feature view models (≥ 90% in Domain), run `swiftlint lint --strict` with 0 errors/warnings, update `CHANGELOG.md` and `Docs/PROJECT_STRUCTURE.md`, and prepare `v2.1.0`.

## Steps

1. Branch `feature/phase_19_visual_qa_and_release` from `main`.
2. Expand `SampleTVUITests.swift` and fill any unit-test gaps uncovered by `xccov`.
3. Perform full simulator visual + VoiceOver inspection across Login, Discover (Movies & TV Shows), Details, Player (live stream + error overlay), Categories, Category Results, Search, and Profile.
4. Run full verification suite (all packages + app unit tests + `SampleTVUITests` + `xccov` + `swiftlint lint --strict`).
5. Update `CHANGELOG.md` (`[2.1.0]`) and `Docs/PROJECT_STRUCTURE.md`, and prepare the release PR + `v2.1.0` tag per `Docs/RELEASE_PROCESS.md`.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVDomain SampleTVAPI SampleTVPersistence SampleTVPlaybackProgress SampleTVUI SampleTVDiscovery SampleTVSearch SampleTVPlayer SampleTVAuth SampleTVProfile; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -enableCodeCoverage YES -resultBundlePath build/Release_v2.1.0.xcresult
xcrun xccov view --report --only-targets build/Release_v2.1.0.xcresult
swiftlint lint --strict
```

## Definition of done

- All 10 package test suites, `SampleTVTests`, and `SampleTVUITests` pass on the Apple TV simulator.
- Code coverage is ≥ 85% across Domain, API, Persistence, and ViewModels (≥ 90% for Domain).
- `swiftlint lint --strict` passes with 0 errors and 0 warnings.
- Every UI screen passes visual inspection with zero clipped text, transparent cover bleed-through, truncated pickers, or broken 403 streams.
- `CHANGELOG.md` and `Docs/PROJECT_STRUCTURE.md` reflect `v2.1.0`.
