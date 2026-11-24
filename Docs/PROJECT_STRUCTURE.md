# Project structure and status

What exists today, what each phase adds, and where the supporting files go. Update the **status table** in every
phase PR; it is the source of truth that [AGENTS.md](../AGENTS.md) points agents to.

## Status

| Phase | Scope | Status | Branch |
|-------|-------|--------|--------|
| Planning | README, AGENTS, Docs, verified templates | ✅ Merged | `main` |
| 1 | Foundation: Swift 6, CI, DI skeleton | ✅ Merged | `main` (v0.1.0) |
| 2 | Domain layer (`SampleTVDomain`) | ✅ Complete & Verified | `main` / `feature/add-workspace` |
| 3 | API layer (`SampleTVAPI`) | ✅ Complete & Verified | `main` / `feature/add-workspace` |
| 3b | [Stabilization](Phase03_API_Layer/Documentation/Phase_03b_Stabilization.md): fix 2/3, link packages to the app | ✅ Complete & Verified | `feature/add-workspace` |
| 4 | [Movie discovery](Phase04_Movie_Discovery/Documentation/Phase_04_Movie_Discovery.md) (`SampleTVUI`, `SampleTVDiscovery`) | ✅ Complete & Verified | `feature/phase_04_movie_discovery` |
| 5 | Search (`SampleTVSearch`) | ✅ Complete & Verified | `feature/phase_05_search_module` |
| 6 | Player (`SampleTVPlayer`) | ⏳ Not started | - |

Statuses: ⏳ not started · 🚧 in progress (branch name) · ✅ complete / merged (version tag).

## Today

**Open `SampleTV.xcworkspace`, not `SampleTV.xcodeproj`.** The workspace is the single entry point; packages linked to
the app target through `Scripts/link_package.rb` appear in Xcode as local packages with their schemes and tests.

```
.
├── SampleTV.xcworkspace/        single entry point (open this)
├── SampleTV.xcodeproj/          tvOS app project, scheme "SampleTV"
├── SampleTV/                    app target = composition root (SampleTVApp, AppConfiguration, AppContainer, RootView)
├── SampleTVTests/               unit tests (Swift Testing)
├── SampleTVUITests/             UI tests (XCTest)
├── Packages/
│   ├── SampleTVDomain/          Phase 2 (verified, 22 tests passing)
│   ├── SampleTVAPI/             Phase 3 (verified, 5 tests passing)
│   ├── SampleTVUI/              Phase 4 (verified, 2 tests passing)
│   ├── SampleTVDiscovery/       Phase 4 (verified, 6 tests passing)
│   └── SampleTVSearch/          Phase 5 (verified, 2 tests passing)
├── Scripts/                     link_package.rb (adds a local package to the app target)
├── Config/                      Shared.xcconfig, Secrets.xcconfig(.example), Info.plist
├── Docs/                        architecture, API spec, phase guides, templates
├── .github/  .swiftlint.yml  .gitignore
└── README.md  AGENTS.md  CHANGELOG.md  PHASE_SUMMARY.md
```

**Adding a package (each phase):**
1. Create the package folder under `Packages/<Name>/`.
2. Add `<FileRef location="group:<Name>">` to the `Packages` group in `SampleTV.xcworkspace/contents.xcworkspacedata`.
3. Run `ruby Scripts/link_package.rb <Name>` to link the package product to the app target. Never hand-edit `project.pbxproj`.

## Target (after Phase 6)

```
.
├── README.md  AGENTS.md  CHANGELOG.md
├── .gitignore                       from Docs/templates/gitignore
├── .swiftlint.yml                   from Docs/templates/swiftlint.yml
├── .github/
│   ├── workflows/ci.yml             from Docs/templates/ci.yml
│   └── pull_request_template.md     from Docs/PR_TEMPLATE.md
├── Config/
│   ├── Shared.xcconfig              base configuration for the app target
│   ├── Secrets.xcconfig.example     committed placeholder
│   └── Secrets.xcconfig             git-ignored; holds TMDB_READ_ACCESS_TOKEN
├── SampleTV.xcworkspace/            single entry point (open this)
├── Scripts/link_package.rb          links a local package to the app target
├── SampleTV.xcodeproj/
├── SampleTV/                        app target = composition root
│   ├── SampleTVApp.swift  AppConfiguration.swift  AppContainer.swift  RootView.swift
│   └── Assets.xcassets/
├── SampleTVTests/  SampleTVUITests/
├── Packages/                        local Swift packages, one folder each
│   ├── SampleTVDomain/              entities, MediaRepository port, use cases        (Phase 2)
│   ├── SampleTVAPI/                 TMDB client, DTOs, retry, cache                  (Phase 3)
│   ├── SampleTVUI/                  MediaCard, PosterImage, ImageURLBuilder          (Phase 4)
│   ├── SampleTVDiscovery/           browse grid, details                             (Phase 4)
│   ├── SampleTVSearch/              debounced search, filters                        (Phase 5)
│   └── SampleTVPlayer/              AVKit player                                     (Phase 6)
└── Docs/
```

Each package follows the same layout: `Package.swift`, `Sources/<Name>/…`, `Tests/<Name>Tests/…`.

### Package dependency graph

```
SampleTVDomain      (Foundation only)
├── SampleTVAPI
├── SampleTVUI
│   ├── SampleTVDiscovery
│   └── SampleTVSearch
SampleTVPlayer      (no dependencies)

SampleTV app target imports all of them; nothing imports the app target.
```

Enforced by `Package.swift` plus the custom rules in `.swiftlint.yml`.

## Docs inventory

| File | Purpose |
|------|---------|
| `Docs/ARCHITECTURE.md` | Layers, modules, DI, concurrency, testing |
| `Docs/API_SPECS.md` | TMDB endpoint/error/caching contract |
| `Docs/PROJECT_STRUCTURE.md` | This file |
| `Docs/Phase03_API_Layer/Documentation/Phase_03b_Stabilization.md` | Repairs Phases 2-3 and links packages; do before Phase 4 |
| `Docs/QWEN_PROMPT.md` | Prompt for running the remaining phases with a local coding model |
| `Docs/RELEASE_PROCESS.md` | Branching, CI gates, versioning |
| `Docs/PR_TEMPLATE.md` | PR template, review checklist, rejection reasons |
| `Docs/Phase01_Foundation/Documentation/Phase_01_Foundation.md` | Phase 1 guide |
| `Docs/Phase02_Domain_Layer/Documentation/Phase_02_Domain_Layer.md` | Phase 2 guide |
| `Docs/Phase03_API_Layer/Documentation/Phase_03_API_Layer.md` | Phase 3 guide |
| `Docs/Phase04_Movie_Discovery/Documentation/Phase_04_Movie_Discovery.md` | Phase 4 guide |
| `Docs/Phase05_Search_Module/Documentation/Phase_05_Search_Module.md` | Phase 5 guide |
| `Docs/Phase06_Player_Feature/Documentation/Phase_06_Player_Feature.md` | Phase 6 guide |

### Templates (`Docs/templates/`)

Each was run and checked before being committed. They are *templates* because tooling expects them elsewhere
(repo root, `.github/`, `Config/`); Phase 1 copies them into place.

| Template | Copy to | Verified by |
|----------|---------|-------------|
| `gitignore` | `.gitignore` | – |
| `swiftlint.yml` | `.swiftlint.yml` | SwiftLint 0.65: clean run, and deliberate Domain/feature import violations are flagged with the custom messages |
| `ci.yml` | `.github/workflows/ci.yml` | YAML parses; the simulator-selection, `xcodebuild test` and `xccov` commands were run locally against the real project |
| `Shared.xcconfig` | `Config/Shared.xcconfig` | – (checked in Phase 1 step 4) |
| `Secrets.xcconfig.example` | `Config/Secrets.xcconfig.example` | – |

### Phase guides: shared structure

Each guide has: header table (branch, dependencies, deliverables), file tree, design notes, steps, the code, tests,
verification commands, definition of done and a pointer to the next phase. The Swift code in them is extracted from
packages that were compiled in Swift 6 mode and whose tests ran on the tvOS simulator, so it can be pasted as-is.

## Conventions

- Package names: `SampleTV<Name>`; one library product per package, named the same.
- Branches: `feature/phase_0X_<name>`; tags: `v0.X.0` after each phase merges, `v1.0.0` when Phase 6 ships.
- Commits: Conventional Commits, scope = package (`feat(api): …`, `test(domain): …`, `docs: …`).
- Tests: Swift Testing for unit tests, XCTest for UI tests.
