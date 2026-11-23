# RELEASE_PROCESS.md - GitHub Workflow & Versioning Guidelines

> 🚀 This document outlines the release process for SampleTV including Git branch management, CI/CD pipelines, version tagging, and PR reviews.

---

## 🔄 Git Workflow: GitHub Flow (Feature Branches)

### Standard Process Per Phase:

```bash
# 1. Create Feature Branch (from main branch)
git switch main  
# Pull latest
git pull origin main  
git checkout -b feature/phase_01_foundation  # Or your phase name
# Push to remote
git push -u origin feature/phase_01_foundation

# 2. Implement Phase Code + Commit Changes
# ... (write code, run tests) ...
git add .  
# Write meaningful commit messages
git commit \-m "feat(phase01): [short description]"  
# Example: feat(phase01): Setup DI container with SwiftInject and local SPMs

# 3. Push to Remote Branch
git push origin feature/phase_01_foundation

# 4. Create Pull Request to Main Branch
# - Open PR on GitHub (target: main branch)  
# - Title & body fields must follow template  
# - Include screenshots, API documentation, and performance benchmarks

# 5. Code Review Process (Mandatory)
# - Require minimum 2 approvers for merge
# - Automated checks:
#   • Clippy type safety scan (strict mode)  
#   • SwiftLint compliance check (< 5 violations max)  
#   • CI/CD pipeline (build, test, coverage ≥ 85% target)
# - Manual review: Architecture & code quality

# 6. Merge Commit (Squash Option for Phase Updates)
git merge --squash feature/phase_01_foundation
git push origin main
# Tag release if milestone phase merged
git tag -a v1.0.0 -m "Initial Release"  
git push --tags

# 7. Create Release on GitHub
# - Upload binaries (optional)  
# - Update CHANGELOG.md under [Unreleased] section  
```

---

## 📋 PR Template Requirements

### All PRs Must Include:

```markdown
## Overview
[Short summary of what this PR implements/changes]

## Phases Affected
- Phase X: [Brief description]
- Module Y: [Changes]

## Changes Made
1. Code changes in file(s):
   - `Domain/Sources/Entities.swift` → Added new type for TVShow  
2. Test coverage updates: [List test files modified]
3. CI/CD Pipeline: All pipelines should pass (build, lint, tests)

## Screenshots/UI Changes (if applicable)
[Image/GIF of UI changes - required if any]

## Performance Metrics
- Line increase/decrease: ±X%
- Test coverage before/after: 82.3% → 85.7%  
- Clippy violations: Before X, After Y  

## Breaking Changes?
Yes/No  
If yes: [Describe what changed and migration guide]

## Related Issues (GitHub Links)
#123 - Implement Phase01 DI Container  
#456 - Setup TMDB API client layer  

<!-- Required for Phase merges -->
**Phase X merged - Ready for Release?**  
→ Approve this PR if phase is complete and codebase meets requirements
```

---

## 📦 Phase Completion Requirements

### Before Merging `feature/phase_X`, Must Verify:

1. **Local Tests Pass** (85%+ coverage per module)
   - Run all XCTest/Swift tests locally  
   - Coverage report must be uploaded to PR description  

2. **CI/CD Pipeline Green**  
   - Build ✅ (no compilation errors)  
   - SwiftLint ✅ (< 5 violations max, < 1 critical)  
   - Clippy ✅ (0 failures, type-safe codebase)  
   - Integration Tests ✅ (no flaky tests)  

3. **Architecture Principles Followed**:
   ```swift
   // All added files must conform to:
   
   - Domain Layer has NO external imports  
   - API layer uses ONLY protocol types as dependencies  
   - DI protocols are defined with clear interfaces  
   - UseCases implement pure functions (no side effects)  
   - Tests use proper mocking for all external services  
   
   // Must be verified by:  
   // 1. `swift build --dependency-check` (check dependency graph)  
   // 2. Run Clippy strict mode on codebase  
   // 3. CI checks SwiftLint rules  
   ```

4. **Documentation Complete**
   - ReadMe for module updated  
   - CHANGELOG.md entries added to correct phase section  
   - PR description includes all references + UI screenshots  

---

## 📂 Versioning Schema (Semantic Versioning)

### SampleTV Version Format: `MAJOR.MINOR.PATCH`

### Example Release Cycle:
```bash
# Current version: v0.2.1 (patch release after Phase 4 implementation)

# Next major features will be in v1.x, e.g., v1.0.0 - "Player Implementation"
# After all 6 phases complete and integrated

// Version bumping rules:
- Patch (0.y.z → 0.y+1.z): Bug fixes, non-breaking changes  
- Minor (0.x.z → 0.y+1.z): Feature additions, API-compatible changes  
- Major (x.0.0.z): Breaking changes across phases  

// Release tags created after every phase complete and tested
```

---

## 🏷️ Release Tag Creation Process

### After Phase Merge (if it's a Milestone feature like API or Player):

```bash
# In main branch, bump version for next release
git checkout main  
# Bump version in Package.swift  
# Example: v0.1.2 → v1.0.0 if player phase completed  
# Update CHANGELOG.md  
sed -i '' 's/"Unreleased"/"Unreleased \[v1.0.0\]/{/Package.swift
# Tag release (Git creates branch automatically)  
git tag -a "v1.0.0 - SampleTV Player Module Release" -m "Complete player feature with MVVM architecture" 

# Push tags to origin repository (required for GitLab/GitHub Actions CI)
git push --tags
```

---

## 🔍 Quality Gate Requirements (PR Merges Blocker)

### GitHub Actions Workflow:

```yaml
name: SampleTV Build & Test Pipeline  
on: [push, pull_request]  

jobs:
  build-and-test:
    runs-on: macos-latest  

    steps:
      # Checkout codebase
      - name: Checkout Code
        uses: actions/checkout@v3
        with: { fetch-depth: 0 }  

      # Bump version if phase completed (optional)  
      - name: Setup Package.swift
        run: |
          swift pkg update || echo "SwiftPM not found"

    # Swift Build  
    - name: Build Codebase
      run: 
        swift build --release 

    # Tests + Coverage Check  
    - name: Run Tests & Generate Coverage Report
      run:
        swift test --generate-xctestcoverage-report | tee coverage.txt
      
      - name: Verify Coverage ≥ 85%
        if: always()
        run: | 
          grep -i "percent" coverage.txt 
          (should show >85, fail if <85)

    # Clippy Type Safety Scan  
    - name: Run Clippy Strict Mode Check
      run: |
        swift build --check-yaml && \
        git add . && \
        git commit -q "Clippy check" && \
        swift build --clean
        
    # SwiftLint Compliance  
    - name: Run SwiftLint (CI Gate)
      run: |
        swift build --lint-strict && \
        echo "SwiftLint violations:" && \
        swift lint

  release-check: 
    runs-on: macos-latest
    if: github.event_name == 'workflow_dispatch'
    
    steps:
      # Version check - only create tag if all phases complete  
      - name: Bump Version & Create Release Tag
        id: version-bumper
        run: |
          # Read current version from Package.swift
          grep -oP "\d+\.\d+\.(\d+|\*)/" package.swift > current_version.txt
          
          # If all phases merged (0.x.6.x or higher), bump to v1.0.0
          # Check CHANGELOG.md for "Unreleased" section
          if [ ! -f "CHANGELOG.md" ]; then false; fi
```

---

## 📝 Release Notes Template (`CHANGELOG.md`)

### Format after Merge:
```markdown
# Changelog

## Unreleased (v1.0.0)

### Phase 6: Player Module ✅ Merged
- Add `VideoPlayerService` protocol for AVKit integration  
- Implement playback control UI with swipe-up timeline  
- Add buffer management with retry logic  

### Phase 5: Search Module ✅ Merged  
- Create `SearchQueryBuilder` with filtering capabilities  
- Debounced search results feed (debounce interval: 300ms)  
- Pagination support for large search results sets  

## [Previous Phase]

### Phase 4: Movie Discovery Feature
- Implement SwiftUI view models with Combine state management  
- UI integration with navigation patterns  

... and so forth down to `Unreleased` section.
```

---

*This document serves as the official guideline for all PR merges, version bumps, and release tags across SampleTV's GitHub workflows.*
