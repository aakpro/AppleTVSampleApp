# Release process

How work moves from a branch to `main` to a tagged release. The repository is hosted on GitHub
(`origin`), the default branch is `main`, and CI is `.github/workflows/ci.yml` (installed in Phase 1).

## Branching: GitHub Flow

- `main` is always green and releasable. **Never commit to it directly.**
- One branch per phase (or per fix): `feature/phase_0X_<name>`, `fix/<short-description>`, `docs/<short-description>`.
- Branch from an up-to-date `main`, keep branches short-lived, rebase on `main` if it moves.

```bash
git switch main && git pull --ff-only origin main
git switch -c feature/phase_02_domain_layer
# ... work in small commits ...
git push -u origin feature/phase_02_domain_layer
```

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org), scope = package:
`feat(domain): add SearchQuery validation`, `fix(api): honour Retry-After on 429`, `docs: clarify token setup`.

## Pull requests

1. Open a PR into `main` using the template ([PR_TEMPLATE.md](PR_TEMPLATE.md), installed as
   `.github/pull_request_template.md`).
2. CI must pass (lint, package tests, app tests).
3. **One approval** from someone other than the author. While the project has a single maintainer, the author completes the
   self-review checklist in the template and merges after CI is green; add a second reviewer once there is one.
4. **Squash-merge on GitHub** (button or `gh pr merge --squash`). Do not squash locally and push to `main`; that bypasses
   protection and CI. The squashed commit title must be a Conventional Commit.
5. Delete the branch after merging.

### Branch protection (set once in GitHub → Settings → Branches → `main`)

- Require a pull request before merging
- Require status checks: `lint`, `test`
- Require branches to be up to date
- Disallow force-pushes and deletions

## CI gates

| Gate | Command | Blocks merge? |
|------|---------|---------------|
| SwiftLint | `swiftlint lint` (errors fail, including the architecture-boundary rules) | yes |
| Package tests | `xcodebuild test -scheme <Package> -destination "id=$UDID"` for each folder in `Packages/` | yes |
| App build + tests | `xcodebuild test -scheme SampleTV … -skip-testing:SampleTVUITests` | yes |
| Coverage report | `xcrun xccov view --report --only-targets …` | no, informational |
| UI tests | run locally before release; they are slow on hosted runners | no |

The coverage target (≥ 85% for Domain, API and view models; ≥ 90% for Domain) is checked by reviewers using the report,
not enforced by a script. Warnings from SwiftLint do not fail CI, but a PR should not add new ones.

Run the same checks locally before pushing:

```bash
UDID=$(xcrun simctl list devices available -j \
  | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
swiftlint lint
for d in Packages/*/; do (cd "$d" && xcodebuild test -scheme "$(basename "$d")" -destination "id=$UDID"); done
xcodebuild test -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
```

## Versioning

The app uses [Semantic Versioning](https://semver.org). The version lives in the **Xcode project**
(`MARKETING_VERSION` for the user-visible version, `CURRENT_PROJECT_VERSION` for the build number), **not** in a
`Package.swift`. Local packages are not versioned separately; they are released with the app.

| Release | Meaning |
|---------|---------|
| `v0.1.0` … `v0.6.0` | One tag after each phase merges (Phase 1 → `v0.1.0`, …) |
| `v0.x.y` patch | Bug fix between phases |
| `v1.0.0` | Phase 6 merged, README/Docs final, manual QA done |
| After 1.0 | MAJOR breaking change, MINOR feature, PATCH fix |

## Cutting a release

After the PR is merged:

```bash
git switch main && git pull --ff-only origin main

# 1. Bump versions in Xcode (target SampleTV -> General -> Version / Build), or:
xcrun agvtool new-marketing-version 0.2.0
xcrun agvtool next-version -all

# 2. Move the "Unreleased" entries in CHANGELOG.md under a new "## [0.2.0] - YYYY-MM-DD" heading
git add -A && git commit -m "chore(release): v0.2.0"      # via a PR if main is protected

# 3. Tag and publish
git tag -a v0.2.0 -m "Phase 2: Domain layer"
git push origin v0.2.0
gh release create v0.2.0 --title "v0.2.0" --notes-from-tag      # optional
```

Because `main` is protected, the version-bump commit goes through a small PR like any other change
(`chore(release): v0.2.0`), and the tag is created on the merge commit afterwards. `agvtool` needs
`VERSIONING_SYSTEM = apple-generic` in the project; if it is not set, bump in the Xcode UI instead.

Pre-release checklist:

- [ ] CI green on `main`
- [ ] App runs on an Apple TV simulator with a real token and without one (shows the token screen)
- [ ] UI tests pass locally
- [ ] Phase status table, README roadmap and `CHANGELOG.md` updated
- [ ] No secrets committed: `git ls-files Config` lists only `Shared.xcconfig` and `Secrets.xcconfig.example`

## Changelog

`CHANGELOG.md` at the repo root follows [Keep a Changelog](https://keepachangelog.com). Each PR adds bullets under
`## [Unreleased]` in the right section (`Added`, `Changed`, `Fixed`, `Removed`). A release moves them under the version heading.

```markdown
## [Unreleased]

### Added
- Search tab with debounced queries and client-side genre filtering (#12)

### Fixed
- Retry honours `Retry-After` on HTTP 429 (#14)
```

## Hotfixes

Branch `fix/<name>` from `main`, same PR rules, then a patch release (`v0.x.(y+1)`). There are no long-lived release branches.

## Distribution

This sample is not published to the App Store. If it ever is, add: signing and provisioning via Xcode Cloud or
fastlane, TestFlight, privacy manifest, and replace the embedded TMDB token with a backend proxy (see
[API_SPECS.md](API_SPECS.md)).
