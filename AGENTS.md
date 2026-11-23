# AGENTS.md - Agent Structure & Workflow Configuration

> 💡 This document defines the subagent/autonomous agent structure and workflow for all project phases in SampleTV.

---

## 🤖 Agent Architecture Overview

### Hierarchical Agent System:
```
┌─────────────────────────────────────┐
│       Main Supervisor Agent         │
│  (orchestrates all phase workflows) │
├─────────────────────────────────────┤
│  ┌────────────────────────────────┐ │
│  │  Phase-Specific Autopilot     │ │
│  └────────────────────────────────┘ │
├─────────────────────────────────────┤
│  ┌──────────────────────────────┐  │
│  │  Implementation Subagent     │  │
│  │          (Swift Code Gen)    │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │     Test/Code Review Agent   │  │
│  │         (Lint, Tests)        │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │      Documentation Agent     │  │
│  │       (Doc generation)       │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│    ─────────────────────────────   │
│  External Dependencies:            │
│  - Web Search Agent (API info)     │
│  - Code Gen Agent (Swift templates)│
│  - Testing Agent (Unit tests)      │
└─────────────────────────────────────┘
```

---

## 📋 Phase-by-Phase Agent Assignment

### **Phase 1: Foundation** (`phase_01_foundation`)

#### Primary Agent Tasks:
1. **DI Container Setup** (SwiftInject/Conformance)
   - ✅ Configure Application-wide DI registry
   - ✅ Create DI protocols for all services  
   - ✅ Build injection points for ViewModels
   
2. **Infrastructure Skeleton**  
   - ✅ Set up local SPM structure
   - ✅ Initialize `.build` directories
   - ✅ Setup SwiftLint + Clippy CI pipelines

3. **Environment & Configuration**
   - ✅ Write `.env.example` with TMDB placeholder API key
   - ✅ Generate `Package.swift` dependencies
   - ✅ Create CI/CD configuration files

#### Expected Deliverables:
```bash
# After execution, should produce:
sampletv.xcodeproj/project.pbxproj        # Build config
Package.privateswift.resolved             # Dependency resolution  
.swiftlint.yml                            # Linting rules
Clippy-check.toml                         # Type checks
.swift-version                           # Language target (Swift 6)
```

---

### **Phase 2: API Layer** (`phase_02_api_layer`)

#### Primary Agent Tasks:
1. **Network Layer Implementation**
   - ✅ Implement `APIRepositoryProtocol` 
   - ✅ Create TV Discovery client with retry logic
   - ✅ Build Movie Details endpoint handler
   
2. **Caching Infrastructure**  
   - ✅ Design `CacheAdapterProtocol` (Disk + Memory hybrid)
   - ✅ Implement exponential backoff strategy
   - ✅ Add caching invalidation mechanism

3. **Error Handling**  
   - ✅ Map TMDB errors to ApplicationErrors
   - ✅ Create localized error messages
   - ✅ Implement graceful network failure handling

#### Expected Deliverables:
```
sampletv-api-swift-package/
├── Sources/
│   ├── Networking/APIProtocols.swift
│   ├── TVDiscoveryClient.swift    
│   └── RateLimiter.swift
├── Tests/
│   ├── NetworkTests/
│   └── APIValidationTests.swift
```

---

### **Phase 3: Domain Layer** (`phase_03_domain_layer`)

#### Primary Agent Tasks:
1. **Entity Definitions**  
   - ✅ Define `Movie` and `TVShow` Value Types (immutable)
   - ✅ Create `ContentItem` base protocol
   - ✅ Implement Codable + Equatable protocols

2. **Pure Use Cases**  
   - ✅ `UseCase.GetMoviesBySearchQuery` 
   - ✅ `UseCase.FilterByGenre` 
   - ✅ `UseCase.SearchByTitlePattern`

3. **Dependency Separation Verification**  
   - ✅ Verify no external imports in Domain
   - ✅ Run Clippy strict mode (type safety)

#### Expected Deliverables:
```
sampletv-domain-swift-package/
├── Sources/
│   ├── Entities/Movie.swift
│   ├── Entities/TVShow.swift
│   ├── ValueObjects/{Genre,Rating}.swift
│   └── UseCases/.
```

---

### **Phase 4: Movie Discovery Feature** (`phase_04_movie_discovery`)

#### Primary Agent Tasks:
1. **ViewModel Architecture**  
   - ✅ Implement `MovieDiscoveryViewModel` with Combine
   - ✅ Create state management (loading/filter/results)
   - ✅ Add UI update triggers

2. **View Components**  
   - ✅ Build custom SwiftUIView for movie list  
   - ✅ Implement search bar UI component
   - ✅ Create filtering controls
   
3. **Repository Integration**  
   - ✅ Wire repository abstraction to API client
   - ✅ Integrate domain use cases in ViewModel
   - ✅ Add error handling in ViewModels

#### Expected Deliverables:
```
sampletv-movie-discovery/
├── Sources/
│   ├── Presentation/MovieDiscoveryView.swift
│   ├── ViewModels/MovieDiscoveryViewModel.swift
│   └── Components/.
└── Tests/PresentationTests.swift
```

---

### **Phase 5: Search Module** (`phase_05_search_module`)

#### Primary Agent Tasks:
1. **Search Query Building**  
   - ✅ Create `SearchQueryBuilder` protocol
   - ✅ Implement advanced filtering logic (genre, year)
   
2. **Async State Management**  
   - ✅ Add debouncing for input fields  
   - ✅ Create pagination support (optional)

3. **UI Updates & Optimizations**  
    - ✅ Build real-time search results feed  
    - ✅ Handle infinite scroll scenario

#### Expected Deliverables:
```
sampletv-search-module/
├── Sources/
│   ├── Querying/{SearchQuery,Builders}.swift
│   └── Presentation/SearchViewModel.swift
└── Tests/SearchTests.swift
```

---

### **Phase 6: Player Feature** (`phase_06_player_feature`)

#### Primary Agent Tasks:
1. **Video Player Infrastructure**  
   - ✅ Implement `VideoPlayerService` protocol  
   - ✅ Create player view (native + AVKit integration)
   
2. **Playback Controls**  
   - ✅ Build playback timeline UI
   - ✅ Add volume/buffering controls

3. **State Integration**  
   - ✅ Link player to repository (movie selection)
   - ✅ Add error handling for failed playback

#### Expected Deliverables:
```
sampletv-player-module/
├── Sources/
│   ├── PlayerControls.swift
│   └── VideoPlayerService.swift  
└── Tests/PlayerTests.swift
```

---

## ⚙️ Agent Configuration Template

### For All Phase Autopilot Execution:

```json
{
  "agent_name": "Phase-Specific-Autopilot",
  "agent_type": "implementation_builder", 
  "capabilities": [
    "swift_code_generation",
    "architecture_verification",
    "unit_test_creation",
    "swiftlint_compliance"
  ],
  
  "permissions": {
    "file_access": true,
    "bash_execution": true, 
    "web_search": false,
    "code_generation": true
  },

  "workflow_steps": [
    {
      "step_id": 1,
      "action": "create_file_structure", 
      "files": ["Models.swift", "UseCases.swift"],
      "validation": "SwiftLint compliance check"
    },
    {
      "step_id": 2, 
      "action": "verify_architecture",
      "method": "Clippy type safety scan",
      "failure_threshold": 10 // max violations allowed
    },
    {
      "step_id": 3, 
      "action": "generate_code",
      "templates": ["SwiftUIView", "ViewModel"],
      "output_path": "Presentation/"
    },
    {
      "step_id": 4, 
      "action": "create_tests", 
      "coverage_target": 85,
      "test_framework": "XCTest"
    },
    {
      "step_id": 5, 
      "action": "commit_push",
      "branch_prefix": "feature/phase_",
      "auto_merge_trigger": false
    }
  ]
}
```

---

## 🔄 Agent Execution Loop (Per Phase)

### Standard Autopilot Workflow:

```bash
# Phase X execution triggers this full loop:

1. CREATE_BRANCH
   git checkout -b feature/phase_X
  
2. AUTOPILOT_RUN
   subagent "Phase-X-Agent" \
     prompt "Implement phase_X with all steps in sequence"
  
3. COMMIT_CHANGES
   git add .
   git commit -m "feat(phase_x): [specific description]"

4. PUSH_TO_REMOTE
   git push origin feature/phase_X

5. MERGE_REQUEST_CREATION
   Trigger GitHub Actions (PR validation, CI pipeline)
   
6. CODE_REVIEW
   Manual review + automated checks  
   
7. MERGE_APPROVAL
   Squash merge after all validations passed
   
8. RELEASE_TAGGING
   Optional: Create version tag if it's a milestone phase

9. PROGRESS_REPORT
   Update AGENTS.md with completion status

10. NEXT_PHASE_START
    Prepare for next agent loop when ready
```

---

## 📊 Agent Metrics & Performance Tracking

### Success Criteria per Phase:
- ✅ All CI/CD pipelines green  
- ✅ Code coverage ≥ 85% 
- ✅ No SwiftLint errors (only warnings)
- ✅ Type-safe codebase (Clippy clean)
- ✅ Documentation completeness = 100%

---

## 🧠 Agent Brainstorming Prompts

### For Any Phase:
```swift
// Prompt template for agent generation:

"You are an iOS developer implementing [phase_name]. 

Requirements: 
- Follow Clean Architecture principles strictly
- Use MVVM in presentation layer  
- Implement DI with SwiftInject/Structural Conformances
- All code must be type-safe (no Any/AnyObject outside core)
- Tests must target 85%+ coverage
  
Execute all implementation steps from your AGENTS.md config, 
commit changes, create PR, and report status."
```

---

*This document serves as the central reference for all phase-specific agent deployment and workflow execution.*
