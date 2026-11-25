# Phase 8: Mock Authentication & Login Flow

| | |
|---|---|
| Branch | `feature/phase_08_auth` |
| Depends on | Phase 7b |
| Delivers | `AuthRepository` port & use cases in Domain, `MockAuthRepository` adapter in `SampleTVAPI`, `SampleTVAuth` (`LoginView`, `LoginViewModel`), and session gating in `RootView` |

## Deliverables

```text
Packages/SampleTVDomain/Sources/SampleTVDomain/
└── Auth.swift                         UserAccount, AuthError, AuthRepository, SignIn, SignInDemo, SignOut, LoadCurrentAccount

Packages/SampleTVAPI/Sources/SampleTVAPI/
├── KeychainSessionStore.swift         Security framework Keychain wrapper (Sendable, testable via in-memory stub)
└── MockAuthRepository.swift           actor backed by KeychainSessionStore (swappable for real OAuth/JWT)

Packages/SampleTVAuth/
├── Package.swift                      depends on SampleTVDomain, SampleTVUI
├── Sources/SampleTVAuth/
│   ├── LoginViewModel.swift           @MainActor @Observable final class
│   └── LoginView.swift                tvOS sign-in + quick demo account button
└── Tests/SampleTVAuthTests/
    └── LoginViewModelTests.swift

SampleTV/AppContainer.swift            authRepository + makeLoginViewModel
SampleTV/RootView.swift                session routing (LoginView vs. TabView)
.swiftlint.yml                         add SampleTVAuth to feature-boundary rules
```

## Design

- **Ports and adapters:** `SampleTVDomain` defines `UserAccount`, `AuthError`, and `AuthRepository`. `MockAuthRepository` lives in `SampleTVAPI` as an `actor` backed by `KeychainSessionStore` (`Security` framework) so real OAuth/JWT tokens use the same secure Keychain storage without touching Domain or UI. Unit tests inject an in-memory `SessionStore` stub so tests never touch the system Keychain.
- **tvOS 10-foot ergonomics:** Typing long credentials with the Siri Remote is tedious, so `LoginView` offers both `TextField`/`SecureField` credential sign-in (with validation for `emptyFields` and `invalidCredentials`) and a **"Continue with Demo Account"** button.
- **Session gating:** `RootView` loads `LoadCurrentAccount` on launch via `.task`. Unauthenticated users see `LoginView`; authenticated users enter the `TabView`.

## Steps

1. Branch `feature/phase_08_auth` from `main`.
2. Add `Auth.swift` to `SampleTVDomain` and unit tests in `SampleTVDomainTests`.
3. Add `MockAuthRepository.swift` to `SampleTVAPI` and persistence/validation tests in `SampleTVAPITests`.
4. Create `Packages/SampleTVAuth`, register it in `SampleTV.xcworkspace/contents.xcworkspacedata`, link it with `ruby Scripts/link_package.rb SampleTVAuth`, and add `SampleTVAuth` to `.swiftlint.yml`.
5. Implement `LoginViewModel`, `LoginView`, and `LoginViewModelTests`.
6. Wire `AppContainer` and `RootView` session routing.

## Verification

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for pkg in SampleTVDomain SampleTVAPI SampleTVAuth; do
  (cd "Packages/$pkg" && xcodebuild test -scheme "$pkg" -destination "id=$UDID")
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint
```

## Definition of done

- Empty/malformed credentials surface `AuthError` inline without crashing.
- Demo sign-in and credential sign-in persist across app relaunches.
- `SampleTVAuth` never imports `SampleTVAPI` or other feature packages.
- All package tests, app tests, and `swiftlint lint` pass.

**Next:** [Phase 9: Profile & Account Preferences](../../Phase09_Profile/Documentation/Phase_09_Profile.md)
