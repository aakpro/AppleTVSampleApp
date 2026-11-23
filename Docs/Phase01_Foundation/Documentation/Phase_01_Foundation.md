# Phase 1: Foundation

| | |
|---|---|
| Branch | `feature/phase_01_foundation` |
| Depends on | nothing |
| Delivers | A clean, Swift 6, lint-checked, CI-built app skeleton with configuration/secrets handling and a composition root. No features yet. |

The repository starts as the Xcode tvOS template (SwiftUI + SwiftData, `Item`, `NavigationSplitView`).
This phase replaces the template with the skeleton every later phase builds on.

## Deliverables

```
.gitignore                         from Docs/templates/gitignore
.swiftlint.yml                     from Docs/templates/swiftlint.yml
.github/workflows/ci.yml           from Docs/templates/ci.yml
.github/pull_request_template.md   from Docs/PR_TEMPLATE.md (the template block)
CHANGELOG.md                       already present, add entries as you go
Config/
├── Shared.xcconfig                from Docs/templates/Shared.xcconfig
├── Secrets.xcconfig.example       from Docs/templates/Secrets.xcconfig.example
└── Secrets.xcconfig               local only, git-ignored
SampleTV/
├── SampleTVApp.swift              rewritten (no SwiftData)
├── AppConfiguration.swift         new
├── AppContainer.swift             new
└── RootView.swift                 new
SampleTVTests/AppConfigurationTests.swift   new
```

`SampleTV/Item.swift` and `SampleTV/ContentView.swift` are removed.

## Steps

### 1. Branch and repository hygiene

```bash
git switch -c feature/phase_01_foundation
cp Docs/templates/gitignore .gitignore
cp Docs/templates/swiftlint.yml .swiftlint.yml
mkdir -p .github/workflows Config
cp Docs/templates/ci.yml .github/workflows/ci.yml
cp Docs/templates/Shared.xcconfig Config/Shared.xcconfig
cp Docs/templates/Secrets.xcconfig.example Config/Secrets.xcconfig.example
cp Config/Secrets.xcconfig.example Config/Secrets.xcconfig     # then paste your real token
```

User-specific files are currently tracked. Stop tracking them (this keeps the files on disk):

```bash
git rm -r --cached --ignore-unmatch SampleTV.xcodeproj/xcuserdata \
  SampleTV.xcodeproj/project.xcworkspace/xcuserdata
git ls-files | grep '\.DS_Store$' | xargs git rm --cached
```

Copy the PR template block from [PR_TEMPLATE.md](../../PR_TEMPLATE.md) to `.github/pull_request_template.md`.

### 2. Swift 6 language mode

The template builds in Swift 5 mode (`SWIFT_VERSION = 5.0`). In Xcode: project → target **SampleTV** (and both
test targets) → Build Settings → **Swift Language Mode = Swift 6**. Build and fix any diagnostics before
continuing; after step 4 there is almost no code left to fix. All packages in later phases use
`// swift-tools-version: 6.0`.

### 3. Remove the template code

Delete `Item.swift` and `ContentView.swift`, and the `SwiftData` import and `.modelContainer(...)` in
`SampleTVApp.swift`. (If you later need persistence, add SwiftData back behind a Domain protocol.)

### 4. Configuration and secrets

The app reads the TMDB token from its Info.plist; the value comes from a git-ignored xcconfig file.

1. Xcode → project **SampleTV** → Info → Configurations: set `Config/Shared.xcconfig` as the base configuration
   for **Debug** and **Release** on the *SampleTV* target. `Shared.xcconfig` includes `Secrets.xcconfig` optionally
   (`#include?`), so a clone without secrets (and CI) still builds.
2. Target **SampleTV** → Info → add a custom property `TMDBReadAccessToken` = `$(TMDB_READ_ACCESS_TOKEN)`.
3. In CI the token is not needed; unit tests never call the network.

Verify the value reaches the built app **without printing the token**:

```bash
UDID=$(xcrun simctl list devices available -j \
  | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
xcodebuild build -scheme SampleTV -destination "id=$UDID" -derivedDataPath build/dd
plutil -extract TMDBReadAccessToken raw -o - build/dd/Build/Products/Debug-appletvsimulator/SampleTV.app/Info.plist | wc -c
# more than 1 means a value was injected; 1 means the token is empty (Secrets.xcconfig missing)
```

### 5. App skeleton

All three files below type-check with the tvOS SDK in Swift 6 mode.

**`SampleTV/AppConfiguration.swift`**

```swift
import Foundation

struct AppConfiguration: Sendable {
    let tmdbToken: String

    init(tmdbToken: String) {
        self.tmdbToken = tmdbToken
    }

    init(bundle: Bundle = .main) {
        self.init(tmdbToken: bundle.object(forInfoDictionaryKey: "TMDBReadAccessToken") as? String ?? "")
    }

    /// False when Secrets.xcconfig is missing (empty) or still holds the example placeholder.
    var hasToken: Bool {
        !tmdbToken.isEmpty && tmdbToken != "paste_your_token_here"
    }
}
```

**`SampleTV/AppContainer.swift`**

```swift
/// Composition root. Phases 2-6 add the repository and one factory method per feature.
@MainActor
final class AppContainer {
    let configuration: AppConfiguration

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    static func live() -> AppContainer {
        AppContainer(configuration: AppConfiguration())
    }
}
```

**`SampleTV/SampleTVApp.swift`** and **`SampleTV/RootView.swift`**

```swift
import SwiftUI

@main
struct SampleTVApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
        }
    }
}
```

```swift
import SwiftUI

struct RootView: View {
    let container: AppContainer

    var body: some View {
        if container.configuration.hasToken {
            Text("SampleTV")
        } else {
            ContentUnavailableView(
                "TMDB token missing",
                systemImage: "key.slash",
                description: Text("Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and add your token.")
            )
        }
    }
}
```

**`SampleTVTests/AppConfigurationTests.swift`**

```swift
import Testing
@testable import SampleTV

struct AppConfigurationTests {
    @Test(arguments: ["", "paste_your_token_here"])
    func missingOrPlaceholderTokenIsRejected(token: String) {
        #expect(!AppConfiguration(tmdbToken: token).hasToken)
    }

    @Test func realLookingTokenIsAccepted() {
        #expect(AppConfiguration(tmdbToken: "eyJhbGciOi").hasToken)
    }
}
```

### 6. Lint and CI

- `swiftlint lint` must report **0 errors**. Warnings in code you wrote should be fixed; the Xcode template files
  you deleted were the main source of existing ones.
- Push the branch and confirm the CI workflow runs green. If the runner's Xcode is older than the project's tvOS
  deployment target, select a newer Xcode in the workflow (`sudo xcode-select -s …` or `DEVELOPER_DIR`) or use a newer runner image.
- Enable branch protection on `main` (see [RELEASE_PROCESS.md](../../RELEASE_PROCESS.md)).

### 7. Packages directory

Do **not** create empty packages. `Packages/` appears with the first package in Phase 2. The CI package loop is
already written to do nothing when it does not exist.

## Verify

```bash
xcodebuild test -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests   # TEST SUCCEEDED
swiftlint lint --strict --quiet | grep -c "error:"                                        # 0
git status --short                                                                       # no secrets, no xcuserdata
git check-ignore -v Config/Secrets.xcconfig                                              # matched by .gitignore
```

Run the app on an Apple TV simulator: with a token you see "SampleTV"; delete the token and you see the
"TMDB token missing" screen instead of a crash.

## Definition of done

- [ ] App builds and tests pass in **Swift 6 language mode**; template code is gone.
- [ ] `.gitignore`, `.swiftlint.yml`, CI workflow, PR template are in place; CI is green on the PR.
- [ ] `Config/Secrets.xcconfig` is ignored; `Secrets.xcconfig.example` is committed; the token reaches `AppConfiguration`.
- [ ] `swiftlint lint` has no errors.
- [ ] Status table in `PROJECT_STRUCTURE.md` and `CHANGELOG.md` updated.

## Next

[Phase 2](../../Phase02_Domain_Layer/Documentation/Phase_02_Domain_Layer.md): the Domain package.
