# Phase 9: Profile Page & Account Preferences

| | |
|---|---|
| Branch | `feature/phase_09_profile` |
| Depends on | Phase 8 (`SampleTVAuth`) |
| Delivers | `ViewerProfile` & `UserPreferences` in Domain, `MockProfileRepository` in `SampleTVAPI`, `SampleTVProfile` (`ProfileView`, `ProfileViewModel`), and the Profile tab in `RootView` |

## Deliverables

```text
Packages/SampleTVDomain/Sources/SampleTVDomain/
└── Profile.swift                      ViewerProfile, UserPreferences, ProfileRepository, use cases

Packages/SampleTVAPI/Sources/SampleTVAPI/
└── MockProfileRepository.swift        actor backed by UserDefaults

Packages/SampleTVProfile/
├── Package.swift                      depends on SampleTVDomain, SampleTVUI
├── Sources/SampleTVProfile/
│   ├── ProfileViewModel.swift         @MainActor @Observable final class
│   └── ProfileView.swift              account header, profile switcher, preferences, sign out
└── Tests/SampleTVProfileTests/
    └── ProfileViewModelTests.swift

SampleTV/AppContainer.swift            profileRepository + makeProfileViewModel
SampleTV/RootView.swift                Profile tab + sign-out transition
.swiftlint.yml                         add SampleTVProfile to feature-boundary rules
```

## Design

- **Mocked multi-profile support:** `MockProfileRepository` provides household profiles (e.g., `"Main"`, `"Kids"`, `"Guest"`) and per-profile `UserPreferences` (`defaultKind`, `autoplayTrailers`).
- **Watch history integration:** `ProfileViewModel` reads `PlaybackProgressStore.recentlyWatched(maxCount:)` to show a watch-history count and offers a **"Clear Watch History"** action.
- **Clean sign-out:** Pressing **Sign Out** triggers a confirmation dialog, calls `SignOut`, and notifies `RootView` to reset navigation/covers and return to `LoginView`.

## Steps

1. Branch `feature/phase_09_profile` from `main`.
2. Add `Profile.swift` to `SampleTVDomain` and `MockProfileRepository.swift` to `SampleTVAPI`.
3. Create `Packages/SampleTVProfile`, register in `SampleTV.xcworkspace/contents.xcworkspacedata`, link via `ruby Scripts/link_package.rb SampleTVProfile`, and update `.swiftlint.yml`.
4. Implement `ProfileViewModel`, `ProfileView`, and `ProfileViewModelTests`.
5. Add the **Profile** tab in `RootView` wired from `AppContainer`.

## Verification

- `xcodebuild test` passes for `SampleTVDomain`, `SampleTVAPI`, `SampleTVProfile`, and `SampleTV`.
- `swiftlint lint` passes with 0 errors.

## Definition of done

- Users can view account info, switch mocked viewer profiles, toggle preferences, clear watch history, and sign out back to `LoginView`.

**Next:** [Phase 10: Categories & Multi-Shelf Discovery](../../Phase10_Categories/Documentation/Phase_10_Categories.md)
