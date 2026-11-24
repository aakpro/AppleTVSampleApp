# Phase 3b: Stabilization (do this before Phase 4)

| | |
|---|---|
| Branch | `feature/phase_03b_stabilization` (from `main`) |
| Depends on | Phases 1-3 as merged |
| Delivers | Domain and API packages that build and pass tests, and an app target that links them |

Phases 2 and 3 were merged and reported as complete, but a verification run (2026-11-24) shows they are not:

| Where | Failure |
|-------|---------|
| `Packages/SampleTVDomain/Tests/.../MediaFilterTests.swift:61` | `func yearRangeIsClosed(bothBoundsInclusive)` is not valid Swift. Rename to `yearRangeIsClosedOnBothBounds()`. Check the `item(...)` helper signatures used in this file against the helper actually defined. |
| `Packages/SampleTVAPI/Sources/.../Transport.swift` | `TMDBConfiguration.url(path:)` is invalid and unused; delete it. `RetryPolicy` is wrong (`attempts`/`retryAfter`/`delaySeconds`); replace it with the reference version in [Phase 3](Phase_03_API_Layer.md) (`maxAttempts`, `baseDelay: Duration`, `delay(afterAttempt:retryAfter:)`, `import Foundation` for `pow`). |
| `Packages/SampleTVAPI/Sources/.../TMDBClient.swift` | Compiles once `RetryPolicy` is restored; it already calls `maxAttempts` and `delay(afterAttempt:retryAfter:)`. |
| `SampleTV.xcodeproj` | The app target links no packages: `AppContainer.swift` fails with "Unable to resolve module dependency: SampleTVAPI / SampleTVDomain". The tail of `project.pbxproj` also holds junk entries pointing at the non-existent `Packages/SampleTVDomain-Swift.swift-package/`. |

## Steps

1. Branch from `main`. Fix the Domain test and the API sources as described, using the Phase 2/3 documents as the
   reference. Do not change public Domain API; fix the broken files only.
2. Compare the other API files (`DTOs.swift`, `TMDBMediaRepository.swift`, `URLSession+TMDB.swift`,
   `TMDBClientTests.swift`) with the Phase 3 reference and repair any further drift. Add `LiveTMDBTests.swift`
   (opt-in, skipped without `TMDB_READ_ACCESS_TOKEN`) if it is missing.
3. Link both packages to the app target. **Never hand-edit `project.pbxproj`.** Use the helper:
   ```bash
   ruby Scripts/link_package.rb SampleTVDomain
   ruby Scripts/link_package.rb SampleTVAPI
   ```
   The script is idempotent and also drops the junk entries. It rewrites the pbxproj in canonical form, so a large
   diff in that file is expected.
4. Build and test everything (see Verify). Fix `SampleTVTests/SampleTVTests.swift` (an empty template test) by deleting it.
5. Update `PHASE_SUMMARY.md` and the status table in `Docs/PROJECT_STRUCTURE.md`.

## Verify

```bash
UDID=$(xcrun simctl list devices available -j | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')
for p in SampleTVDomain SampleTVAPI; do
  (cd Packages/$p && xcodebuild test -scheme $p -destination "id=$UDID" -enableCodeCoverage YES) || exit 1
done
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
swiftlint lint --quiet | grep -c "error:"    # 0
```

## Definition of done

- [x] Both packages build and their tests pass on the tvOS simulator.
- [x] The app target builds and links `SampleTVDomain` and `SampleTVAPI`.
- [x] `project.pbxproj` has no references to `SampleTVDomain-Swift.swift-package`.
- [x] `PHASE_SUMMARY.md` and the status table match reality.

## Next

[Phase 4](../../Phase04_Movie_Discovery/Documentation/Phase_04_Movie_Discovery.md).
