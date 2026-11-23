# PR_TEMPLATE.md - Pull Request Template & Review Guidelines

> 🔍 This document defines the mandatory review process, approval requirements, and validation checks for all PRs in SampleTV.

---

## 📝 Mandatory PR Fields (Required)

### All PRs must include:

```markdown
## Overview
[**Short description** of what change this PR makes - max 1 line]  
Example: Implement Phase03 Domain Layer with pure use cases

## Architecture Changes
[List affected layers/modules:]
- ✅ Domain Layer: Added GetMovies implementation (pure Swift)  
- ❌ No API changes (domain must remain dependency-free)  

## Technical Details

### Code Quality Checks
- [ ] Clippy strict type scan passed (no failures)  
- [ ] SwiftLint violations ≤ 5 (lint-strict mode passed)  
- [ ] Dependency check shows no circular imports  

### Testing Requirements  
- [ ] Unit test files created/modified (85%+ coverage target)  
- [ ] Integration tests run locally before PR submission  
- [ ] No flaky tests (all deterministic)  

## UI Changes (if applicable)
[**Description of visual/UI alterations:]**
1. Added new View component: MovieListGrid.swift
2. Modified state flow in ViewModel
3. Screen size compatibility tested

## Screenshots Required (If UI Changed)

### Before vs After Comparison
[Screenshot 1: Before - grayed out or diff view]  
[Screenshot 2: After - feature working correctly]  
[Screenshot 3: Real-world usage on device]

## Performance Metrics  

### Code Size Changes
- Lines added: +450 (mostly tests)
- Modules touched: 3 (Domain, Presentation, API)

### CI/CD Pipeline Status
- Build Time: ±5s (acceptable variance)  
- Test Coverage Target: ≥85% achieved: Yes ✅  

## Breaking Changes Required?

Yes/No

If YES - List all changes:
1. `sampletv-domain-swift-package` exports new entity type: TVShow
2. API layer protocol updated with new cache parameters
3. DI container requires migration guide in CHANGELOG.md

## Migration Guide (Required if breaking)
- Step 1: Update Domain entities to use new base class
- Step 2: Modify ViewModel dependencies via struct injection  
- Version bump: minor/patch as appropriate

## Related Issues
[GitHub Issue(s) linked using #issue-number syntax]
- #123 - Implement domain layer for pure business logic
- #456 - Add search query building utilities

## Implementation Status (Phase X specific)

✅ Local Testing Complete  
✅ All Dependencies Type-Safe  
✅ DI Protocols Verified  
✅ Clippy Strict Mode Passed  

## Approvals Required

**Required:**
- [ ] Main developer review: Architecture & code quality ✅  
- [ ] Second approver: Security & type safety ✅  

**Minimum 2 reviewers needed + both must approve before merge.

## CI Checks Passing (Automated)

```yaml
# From GitHub Actions workflow:
[Build - ✅]   # swift build --release  
[Lint - ✅]    # swift lint -strict  
[Clippy - ✅]  # Type safety scan  
[Test - ✅]    # XCTest suite passes (85%+ coverage)  
```

**If any CI check FAILS, PR must NOT be merged and author must fix before retrying.
```

---

## 🚫 PR Rejections (Common Reasons)

1. **Circular Dependencies Detected** - Must use dependency injection protocol types instead of passing concrete classes directly
2. **Type Safety Violations** - Domain layer has Any/AnyObject usage without justification
3. **Coverage Below 85%** - Unit tests insufficient or flaky
4. **Architecture Violations** - API layer importing entities from domain or using direct protocol implementations in production code
5. **No Screenshots** (if UI changed)  
6. **CI Pipeline Failures** (not all passing before merge)

---

## ✅ Merge Approval Process

### Required Approvals:

1. **Phase Lead Review** - Architecture & implementation strategy verified  
2. **Code Quality Review** - Type safety, linting, CI checks passed  

### After All Checks Pass:

```bash
# Merge with squash option for clean history
git merge --squash origin/feature/phase_01_foundation  
git push origin main  
# Push tags if milestone phase completed
git push --tags

# Then bump version in Package.swift accordingly (per RELEASE_PROCESS.md)
```

---

*This PR template and review guidelines document all approvals required before any code is merged to main across SampleTV.*
