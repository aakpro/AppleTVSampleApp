# Prompt for a local coding model (e.g. qwen3-coder:30b)

Paste everything below the line as the first message. Run it from the repository root in an agent harness that can
read/write files and run shell commands.

---

You are implementing the remaining phases of SampleTV, a tvOS 17 SwiftUI app (Swift 6 language mode, Clean Architecture, local Swift packages).
Work directory: `/Users/aakpro/Desktop/SampleTV`.
You execute written plans; you do not redesign them.

## Current Baseline (Already Complete & Verified)
- Phase 1 (Foundation): Complete & released (v0.1.0).
- Phase 2 (Domain layer: `SampleTVDomain`): Complete & verified (22/22 unit tests passing).
- Phase 3 (API layer: `SampleTVAPI`): Complete & verified (5/5 unit tests passing).
- Phase 3b (Stabilization): Complete & verified. Both packages are linked to `SampleTV`, and `xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV` passes.

## Read First (in this order)
1. `AGENTS.md` (hard rules and constraints)
2. `Docs/PROJECT_STRUCTURE.md` (package map and status table)
3. `Docs/ARCHITECTURE.md` (clean architecture boundaries)
Then, for each phase, read that phase's document in full before writing any code.

## Phases to Implement, Strictly in This Order
1. **Phase 4: Movie Discovery**
   - Doc: `Docs/Phase04_Movie_Discovery/Documentation/Phase_04_Movie_Discovery.md`
   - Branch: `feature/phase_04_movie_discovery` (create from current branch / `main`)
   - Deliverables: `Packages/SampleTVUI` and `Packages/SampleTVDiscovery`
2. **Phase 5: Search Module**
   - Doc: `Docs/Phase05_Search_Module/Documentation/Phase_05_Search_Module.md`
   - Branch: `feature/phase_05_search_module` (create from `feature/phase_04_movie_discovery`)
   - Deliverables: `Packages/SampleTVSearch`
3. **Phase 6: Player Feature & Final Integration**
   - Doc: `Docs/Phase06_Player_Feature/Documentation/Phase_06_Player_Feature.md`
   - Branch: `feature/phase_06_player_feature` (create from `feature/phase_05_search_module`)
   - Deliverables: `Packages/SampleTVPlayer`, final `AppContainer`, and `RootView`

Each branch starts from the previous phase's branch. Complete and verify each phase fully before moving to the next. Never work on two phases at once.

## Method for Every Phase
1. Create and switch to the phase branch. Read the phase documentation carefully.
2. Create the files exactly as the document's code blocks specify. Do not "improve" or redesign working code. Make only the minimal fixes required by the compiler or tests.
3. When creating a new local package under `Packages/<Name>/`:
   - Register it in `SampleTV.xcworkspace/contents.xcworkspacedata` by adding `<FileRef location="group:<Name>">` inside `<Group location="container:Packages" name="Packages">`.
   - Link it to the app target with: `ruby Scripts/link_package.rb <Name>`.
   - **Never hand-edit `SampleTV.xcodeproj/project.pbxproj`.**
4. Write all unit tests listed in the document.
5. Resolve the tvOS simulator ID:
   ```bash
   UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
   ```
6. Run the document's **Verify** commands for the packages and the workspace:
   ```bash
   xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
   swiftlint lint --quiet
   ```
7. Fix any compiler or test errors by reading the exact error messages. If the same error persists after 3 attempts, stop and report it.
8. Update `CHANGELOG.md` and the status table in `Docs/PROJECT_STRUCTURE.md` (mark ✅ only after Verify passes).
9. Make small logical commits using Conventional Commits with the package name as scope (e.g., `feat(discovery): add DiscoveryView and ViewModel`).
10. Output "PHASE <n> DONE" with a summary of the test results, then proceed to the next phase.

## Critical Hard Constraints
- **Target OS:** Deployment target is **tvOS 17.0**. Do NOT use tvOS 18 APIs (`Tab(...)`, `role: .search`). Use `.tabItem` and standard tvOS 17 navigation.
- **tvOS Remote & Focus:** Use focusable controls (`Button` with `.buttonStyle(.card)` or `.plain`). Do not use `.onTapGesture`; interaction must be drivable via the Siri Remote focus engine.
- **Swift Concurrency:** Swift 6 language mode. ViewModels MUST be `@MainActor @Observable final class`. Domain entities and DTOs are `Sendable` value types. Use `async/await`; do not introduce Combine into feature view models.
- **Dependency Flow:** Feature packages (`SampleTVUI`, `SampleTVDiscovery`, `SampleTVSearch`, `SampleTVPlayer`) depend on `SampleTVDomain`. Feature packages NEVER import `SampleTVAPI` or each other (except `Discovery` and `Search` importing `SampleTVUI`). Only the `SampleTV` app target imports all packages.
- **Testing:** Unit tests must use **Swift Testing** (`import Testing`, `@Test`, `#expect`). Stub repositories and network transports; tests must never hit the real network.
- **Secrets:** Never touch `Config/Secrets.xcconfig` or commit API tokens.

## When to Stop and Report
- A document specification contradicts the codebase and the fix is ambiguous.
- A build or test error fails 3 consecutive times with the same issue.
- A change to `project.pbxproj` is needed that `ruby Scripts/link_package.rb` cannot perform.
- The simulator or Xcode toolchain is unavailable.
