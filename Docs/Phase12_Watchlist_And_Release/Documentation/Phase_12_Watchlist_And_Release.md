# Phase 12: Watchlist, UI Tests & Release v2.0

| | |
|---|---|
| Branch | `feature/phase_12_watchlist_and_release` |
| Depends on | Phase 11 |
| Delivers | `WatchlistStore` (My List) across Details/Discovery/Profile, tvOS XCUITest smoke suite, Siri Remote focus polish, and `v2.0.0` release prep |

## Deliverables

```text
Packages/SampleTVDomain/Sources/SampleTVDomain/
└── Watchlist.swift                    WatchlistStore protocol, ToggleWatchlist, GetWatchlist

Packages/SampleTVAPI/Sources/SampleTVAPI/
└── UserDefaultsWatchlistStore.swift   actor-backed persistence (per active profile)

Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
└── DetailsView.swift                  "Add to My List" / "In My List" toggle button

Packages/SampleTVProfile/Sources/SampleTVProfile/
└── ProfileView.swift                  "My List" saved titles shelf

SampleTVUITests/
└── SampleTVUITests.swift              XCUITest smoke suite (demo login -> tabs -> details -> player)
```

## Design

- **Watchlist / My List:** Lets users bookmark movies and shows from `DetailsView` and view them in `ProfileView` (and optionally a "My List" shelf on `DiscoveryView`), scoped to the active `ViewerProfile`.
- **XCUITest smoke coverage:** Automate the core Siri Remote focus paths using `XCUIRemote.shared`: demo sign-in, switching between Discover / Categories / Search / Profile tabs, opening `DetailsView`, launching `PlayerView`, and dismissing via Menu.
- **Release checklist:** Verify ≥ 85% unit test coverage on Domain, API, and ViewModels (`xccov`), update `CHANGELOG.md`, `Docs/PROJECT_STRUCTURE.md`, and tag `v2.0.0`.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -enableCodeCoverage YES -resultBundlePath build/Release.xcresult
xcrun xccov view --report --only-targets build/Release.xcresult
swiftlint lint
```

## Definition of done

- All package unit tests, `SampleTVTests`, and `SampleTVUITests` pass on the Apple TV simulator.
- `swiftlint lint` reports 0 errors.
- `CHANGELOG.md` and `Docs/PROJECT_STRUCTURE.md` reflect `v2.0.0`.
