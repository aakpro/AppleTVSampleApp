# PROJECT_STRUCTURE.md - SampleTV Complete File & Phase Inventory

> 📋 Overview: This is the authoritative inventory of all documentation files and phase-specific implementation artifacts for SampleTV.

---

## 📦 Root Level Documentation Files (Phase 1-6 Foundation)

### Core Project Docs:
```
SampleTV/
├── README.md                     # Main project overview & philosophy  
├── AGENTS.md                     # Agent architecture per phase workflow  
├── ARCHITECTURE.md              # Clean Architecture vertical/horizontal slicing pattern definition  
├── API_SPECS.md                 # TMDB API integration specs, endpoints & caching strategy  
├── RELEASE_PROCESS.md           # GitHub workflow & version tagging guidelines  
├── PR_TEMPLATE.md               # Mandatory code review requirements per phase  
├── Package.swift                # SPM manifest configuration  
└── CHANGELOG.md                 # Unreleased/Phase-specific changelog entries
```

### Configuration Files:
```
SampleTV/
├── .env.example                  # TMDB_KEY placeholder (gitIgnores .env file)  
├── .swiftlint.yml                # SwiftLint rules config (strict mode enforced)  
├── Clippy-check.toml             # Type safety strictness configuration  
├── .github/workflows/
│   └── build.yml                 # CI/CD pipeline (Build + Lint + Test + Coverage Check)  
└── Package.swift                  # SwiftPM Manifest (Phase 1 dependencies only)  
```

---

## 📦 Phase File Inventory (`phase_*/*`)

### **Phase 01: Foundation Files**
```
SampleTV/Phase01_Foundation/Documentation/
├── Phase_01_Foundation.md    # Phase 01 specific guides & success criteria
│
# Phase 1 Code Structure (Foundation):
Example: (if not yet implemented by you, or for reference):

sampletv-app/Sources/
├── AppEntry.swift        # Application entry point, DI container launch  
└── DIContainer.swift     # Dependency injection setup, factory methods & protocols
  
# Expected CI Pipeline outputs after Phase 01 merge:
✅ SwiftLint violations ≤ 5 in strict mode
✅ Clippy type safety scan (zero failures)  
✅ SPM graph shows no circular dependencies detected
```

---

### **Phase 02: API Layer Files**
```
SampleTV/Phase02_API_Layer/Documentation/
├── Phase_02_API_Layer.md    # TMDB client & caching specifications (reference)

sampletv-api-swift-package/
├── Package.swift         # API module SPM dependencies + configuration  
└── Sources/Networking/
    ├── APIProtocols.swift      # Protocol definitions for all API interfaces  
    ├── NetworkManager.swift     # URLSession wrapper with timeout config  
    ├── TVDiscoveryClient.swift  # TMDB client implementation, rate limiter logic  
    └── RateLimiter.swift        # Exponential backoff strategy implementation

# Expected CI Pipeline outputs after Phase 02 merge:
✅ Build + Lint passes (SwiftLint < 5 violations)  
✅ Clippy type safety scan passes (no API violations in Presentation layer)  
✅ Network tests mockable & deterministic
```

---

### **Phase 03: Domain Layer Files**
```
SampleTV/Phase03_Domain_Layer/Documentation/
├── Phase_03_Domain_Layer.md    # Pure domain entity specifications, UseCase interfaces

sampletv-domain-swift-package/
├── Package.swift         # Minimal deps (only Foundation + Stdlib)  
└── Sources/Entities/
    ├── Movie.swift              # Value type (Codable+Equatable+Hashable)  
    ├── TVShow.swift             # Value type for TV show info  
    └── ContentItem.swift        # Base protocol for content abstraction

# Expected CI Pipeline outputs after Phase 03 merge:
✅ Zero external imports detected in Domain files  
✅ SwiftLint passes (strict mode compliance)  
✅ Clippy strict type checks pass (no Any/AnyObject usage in domain)  
✅ Unit test coverage ≥ 100% (pure function determinism)
```

---

### **Phase 04: Movie Discovery Files**
```
SampleTV/Phase04_Movie_Discovery/Documentation/
├── Phase_04_Movie_Discovery.md    # MVVM + ViewModel & View specifications

sampletv-movie-discovery/
├── Package.swift  
└── Sources/Presentation/
    ├── Views/MovieDiscoveryView.swift          # Main UI component for discovery  
    ├── Components/MovieCard.swift               # Reusable card view  
    ├── Components/SearchBarComponent.swift       // Search input element
    
📍 ViewModels:
├── ViewModels/MovieDiscoveryViewModel.swift

# Expected CI Pipeline outputs after Phase 04 merge:
✅ Build + Lint + Clippy passes (all green)  
✅ ViewModel tests pass with mocked Repository (85%+ coverage target)  
✅ UI navigation integration verified through SwiftUI patterns
```

---

### **Phase 05: Search Module Files**
```
SampleTV/Phase05_Search_Module/Documentation/
├── Phase_05_Search_Module.md    # Query builders & filtering logic specs

sampletv-search-module/
├── Package.swift  
└── Sources/Querying/
    ├── SearchBuilder.swift              # Build query parameters to send to API  
    ├── GenreQueryBuilder.swift           // Single genre filter builder  
    ├── YearRangeBuilder.swift             // Min/Max year selection  
    └── RatingFilterBuilder.swift          // Minimum rating threshold logic

📍 Filtering State Management:
├── Filters/AdvancedFilters.swift               # Combined filtering parameters  
└── Filters/Debouncer.swift                          // 300-500ms debounce delay pattern implementation

# Expected CI Pipeline outputs after Phase 05 merge:
✅ Build + Lint passes (query builder protocol enforced)  
✅ Clippy strict type checks pass (no Any in query building)  
✅ Debounce functionality tested & verified < 500ms threshold  
✅ Search functionality integrated with repository abstraction pattern
```

---

### **Phase 06: Player Module Files**
```
SampleTV/Phase06_Player_Feature/Documentation/
├── Phase_06_Player_Feature.md    # AVKit integration & playback state patterns

sampletv-player-module/
├── Package.swift  
└── Sources/PlaybackControl/
    ├── VideoPlayerService.swift         # Service protocol, AVKit bindings  
    ├── VideoPlayerControlUI.swift       // SwiftUI controls implementation  

# Expected CI Pipeline outputs after Phase 06 merge:
✅ Build + Lint + Clippy passes (avfoundation integration patterns)  
✅ Unit tests verified with mocked video data (no actual files needed in phase 6 test)  
✅ Repository state integration functional (last-played position pattern)  
```

---

## 🔄 Complete Implementation Loop Checklist (All Phases)

### Per Phase Merge Requirements:
1. ✅ **Local Tests Pass** - `swift test` runs with ≥85% coverage on all modules  
2. ✅ **CI/CD Pipeline**: All pipelines green (Build + Lint + Clippy type-safe check + Test suite passes)  
3. ✅ **Clippy Strict Mode** - Zero type safety violations across codebase  
4. ✅ **SwiftLint Compliance** - < 5 violations in strict mode, all rules passing  

---

## 📊 Git Workflow Status (SampleTV Repository)

### Branch Structure:
```
origin/master           # Main branch (merged from phase releases)  
├── feature/phase_01_foundation        # ✅ Merged ✅ Released v0.1.0 (Foundation + DI container setup)  
    ├── sampletv-app/Sources/AppEntry.swift          # Application entry point  
    └── sampletv-app/Sources/DIContainer.swift       # Dependency injection configuration
├── feature/phase_02_api_layer      # ✅ Merged ✅ Released v0.2.0 (TMDB API + caching)  
├── feature/phase_03_domain_layer    # ✅ Merged ✅ Released v0.3.0 (Domain Entities + UseCases)  
├── feature/phase_04_movie_discovery   # ⏳ Not yet merged
├── feature/phase_05_search_module      # ⏳ Not yet merged
└── feature/phase_06_player_feature     # ⏳ Not yet merged (final phase)  
```

---

## 🎯 Final Release Goals (Post-Phase 6 Merge)

### End-to-End Integration Verification:
After all phases merged, perform:
1. ✅ Full build (`swift build --release` - no warnings/errors)
2. ✅ All CI pipelines green + type-safe checks passing  
3. ✅ Sample video playback functional (mocked or real for AVKit testing phase 6+)  
4. ✅ Repository state integration working across all layers

---

*This document serves as the master inventory for all documentation & phase files across SampleTV's architecture.*
