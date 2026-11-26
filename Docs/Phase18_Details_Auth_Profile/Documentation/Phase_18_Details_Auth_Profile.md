# Phase 18: Cinematic Details Screen, Trailers UX & Onboarding

| | |
|---|---|
| Branch | `feature/phase_18_details_auth_profile` |
| Depends on | Phase 17 |
| Delivers | Opaque backdrop-driven `DetailsView` with rich metadata and padded CTAs, autoplay-trailer preference wiring, flash-free `RootView` session launch, tvOS-ergonomic `LoginView`, and clean centered `ProfileView` |

## Deliverables

```text
SampleTV/
├── Navigation/RootView.swift              .checkingSession launch state (eliminate LoginView flash)
├── Navigation/RootViewModel.swift         session & active-profile state
└── Navigation/DetailsScreen.swift         autoplayTrailers preference wiring

Packages/SampleTVDiscovery/Sources/SampleTVDiscovery/
├── DetailsViewModel.swift                 formatted runtime/seasons/rating helpers + autoplayTrailers flag
└── DetailsView.swift                      opaque backdrop scrim, rich metadata row, padded bordered/prominent CTAs, TMDB footer

Packages/SampleTVAuth/Sources/SampleTVAuth/
└── LoginView.swift                        centered glass card, Demo CTA focus-first ergonomics, equal-width buttons

Packages/SampleTVProfile/Sources/SampleTVProfile/
├── ProfileViewModel.swift                 expose authenticated UserAccount displayName/email
├── ProfileView.swift                      inline header (no floating title), constrained column width, consistent destructive buttons
└── Sections/                              updated avatar cards, Preferences full-width picker, singularized Watch History
```

## Design

- **Opaque, cinematic `DetailsView`:**
  - Fix `.fullScreenCover` bleed-through by backing `DetailsView` with a full-bleed `backdropPath` image (`w1280`, falling back to blurred `posterPath` on a dark `#0E1015` surface) and a multi-stop dark vignette gradient so foreground typography always has crisp contrast.
  - Render a structured metadata line below the title: **year** (`2022`), **TMDB rating** (`★ 8.1`), **runtime** (`2h 06m`) or **season count** (`4 Seasons`), and genre pills.
  - Replace cramped `.card` text buttons with properly padded `.borderedProminent` **Play / Resume MM:SS** (`play.fill`), `.bordered` **Watch Trailer** (`play.rectangle`), and `.bordered` **Add to My List / In My List** (`plus` / `checkmark`) buttons. Show a lightweight placeholder/spinner while `DetailsViewModel.state == .loading`.
  - Move the TMDB attribution (`"This product uses the TMDB API..."`) out of the middle of the overview column into a clean, unobtrusive footer below the *More Like This* `MediaShelfRow`.
  - Wire `UserPreferences.autoplayTrailers` from the active profile into `DetailsScreen` / `DetailsView` cleanly without violating tvOS back-navigation.
- **Eliminate `LoginView` flash & improve 10-foot onboarding:**
  - Use an explicit `SessionState` enum (`.checking | .unauthenticated | .authenticated(UserAccount)`) in `RootViewModel` / `RootView` so signed-in users see a clean dark loading view rather than flashing `LoginView` on every launch.
  - Redesign `LoginView` inside a centered translucent surface (`maxWidth: 620`), add a concise subtitle explaining Demo vs. email sign-in, make **Continue with Demo Account** and **Sign In** equal-width padded buttons, and use `@FocusState` so initial focus lands on **Continue with Demo Account** (or **Sign In**) rather than opening focus inside the bright-white `Email` field.
- **`ProfileView` layout & consistency:**
  - Populate `UserAccount.displayName` and `email` in `AccountHeaderSection` (e.g., `"Alex Mercer"` / `"demo@sampletv.app"`) instead of static `"Account"`.
  - Remove the colliding centered `.navigationTitle("Profile")` and use an inline top header.
  - Constrain profile/preferences controls to a comfortable reading width (`maxWidth: 960`) so labels and right-side controls aren't separated by `1800pt`.
  - Style **Profiles** (`Main`, `Kids`, `Guest`) as crisp avatar cards with initials/icons, make **Default media type** a full-width focusable picker matching **Autoplay trailers**, fix `"1 item"` / `"N items"` singularization, display `viewModel.errorMessage` when present, add a confirmation dialog to **Clear Watch History**, and style **Clear Watch History** and **Sign Out** consistently using `.bordered` destructive buttons with generous padding.

## Steps

1. Branch `feature/phase_18_details_auth_profile` from `main`.
2. Update `DetailsViewModel` (metadata formatting + tests) and redesign `DetailsView` (opaque backdrop + gradient scrim, metadata row, prominent/bordered CTAs, TMDB footer, `MediaShelfRow` for *More Like This*).
3. Add `SessionState` to `RootViewModel` / `RootView` (eliminating the launch flash) and wire `autoplayTrailers` into `DetailsScreen`.
4. Redesign `LoginView` (glass card, focus order, equal-width buttons) and verify keyboard/demo login flows.
5. Update `ProfileView` section subviews (inline header, constrained settings width, avatar cards, real account info, singularized history count, error banner, consistent destructive buttons).
6. Verify all package tests, app tests, lint, and manual simulator walkthrough.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVDiscovery SampleTVAuth SampleTVProfile; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID") || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --strict
```

## Definition of done

- `DetailsView` has an opaque cinematic backdrop with zero bleed-through from the underlying `TabView`, crisp padded CTA buttons, complete metadata (year, rating, runtime/seasons), and a clean bottom TMDB footer.
- Relaunching the app while authenticated never flashes `LoginView`.
- `LoginView` opens cleanly without focusing the `Email` field by default and uses balanced button sizing.
- `ProfileView` displays real account info, has no floating `"Profile"` collision, formats `"1 item"` properly, surfaces errors, and uses consistent padded destructive controls.
- All unit tests and `swiftlint lint --strict` pass with 0 errors.

**Next:** [Phase 19: Visual QA, Accessibility & Release `v2.1.0`](../../Phase19_Visual_QA_And_Release/Documentation/Phase_19_Visual_QA_And_Release.md)
