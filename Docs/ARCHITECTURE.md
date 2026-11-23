# ARCHITECTURE.md - Clean Architecture & iOS Enterprise Design Patterns

> 🏛️ This document describes the architectural principles and patterns followed in SampleTV. All code is strict type-safe, conformable, and CI/CD ready.

---

## 🎯 Architectural Philosophy

### Core Principles:
1. **Domain-First** - Business logic lives in Domain Layer with NO external dependencies
2. **Single Responsibility** - Each module, file, and class does ONE thing well  
3. **Composition over Inheritance** - Everything composes rather than inherits
4. **Fail-Safe Design** - Errors are handled gracefully (no unexpected crashes)
5. **Concurrency-First** - Swift 6 structuring concurrency patterns applied everywhere  

---

## 🏗️ Vertical Slicing: Layer Responsibilities

```
┌─────────────────────────────────┐
│   PRESENTATION LAYER            │
│  ┌────────────────────────────┐ │
│  │ • SwiftUI Views           │ │
│  │ • ViewModels (Combine)    │ │
│  │ • UI State Management     │ │
│  └────────────────────────────┘ │
│   ↓ Depends: Application Layer  │
├─────────────────────────────────┤
│      APPLICATION LAYER          │
│  ┌────────────────────────────┐ │
│  │ • Repository Abstraction    │ │
│  │ • UseCase Adapters         │ │
│  │ • Validation Rules          │ │
│  └────────────────────────────┘ │
│   ↓ Depends: Domain Layer       │
├─────────────────────────────────┤
│      DOMAIN LAYER               │
│  ┌────────────────────────────┐ │
│  │  [NO EXTERNAL IMPORTS]     │ │
│  │ • Entity Value Types       │ │
│  │ • Pure Use Cases           │ │
│  │    (no API, no network)    │ │
│  └────────────────────────────┘ │
│   ↓ No Dependencies              │
├─────────────────────────────────┤
│      INFRASTRUCTURE LAYER       │
│  ┌───────────┐ ┌─────────────┐ │
│  │ Network   │  Local Storage │ │
│  │ Layer     │  (Realm/SQL)  │ │
│  └───────────┘ └─────────────┘ │
└─────────────────────────────────┘
```

---

## 🔍 Horizontal Slicing: Feature Module Pattern

### Local Swift Package Structure (`sampletv.xcodeproj`):
```
📦 Root Package (SampleTV)
 ├── 🏠 Application Module / sampletv-app
 │    ├── Sources/
 │    │   ├── DI Container (SwiftInject setup)
 │    │   ├── AppEntry.swift  
 │    │   └── Navigation Manager
 │    └── Tests/IntegrationTests.swift
 │
 ├── ⚡ API Layer / sampletv-api-swift-package
 │    ├── Sources/
 │    │   ├── Networking/APIProtocols.swift
 │    │   ├── API Clients (REST)
 │    │   ├── CacheManager (Hybrid)
 │    │   └── RateLimiter
 │    └── Tests/NetworkTests.swift
 │
 ├── 🏛️ Domain Layer / sampletv-domain-swift-package
 │    ├── Sources/Entities
 │    │   └── Value Types (Movie, Show)
 │    ├── UseCases/PureLogic.swift
 │    └── Tests/DomainTests.swift  
 │
 ├── 🎬 Movie Discovery / sampletv-movie-discovery
 │    ├── Presentation/Views
 │    ├── ViewModels
 │    │   └── Dependency injection points
 │    └── RepositoryIntegration.swift
 │
 ├── 🔍 Search Module / sampletv-search-module
 │    ├── Querying/Builders
 │    └── Presentations
 │
 ├── 🎬 Player Module / sampletv-player-module
 │    └── AVKit Integration
 │
 └── ⚙️ Utilities / sampletv-utils  
     └── Shared helpers/convenience functions
```

---

## 🔌 Dependency Injection Strategy

### Approach**: Structural Conformance + DI Container  

Each module defines its dependencies as **protocols**, then the Application Container creates instances via dependency injection (no Service Locator!):

#### 1. API Layer - Protocols

```swift
// sampletv-api-swift-package/Sources/Networking/APIProtocols.swift
protocol TVRepository<T: Codable> {
    func getTVList(query: String) async throws -> [T]
    func getTVDetails(id: Int) async throws -> T
}

// Implementation in same module (no circular deps!)
class TVAPIClientImplementation conformant: TVRepository {
    // ... network implementation
}
```

#### 2. Domain Layer - Dependencies = Nothing

```swift
// sampletv-domain-swift-package/Sources/UseCases/GetMovies.swift  
struct GetMovies {
    func execute(query: String) throws -> [MovieResult]
    // ZERO dependencies! Pure Swift function
}
```

#### 3. Application Layer - DI Container (SwiftInject Setup)

```swift
// sampletv-app/Sources/DIContainer.swift

let container = try? DIContainer.makeDependencies { 
    inject: APIRepositoryProtocol => TVAPIClientImplementation 
    inject: MovieUseCase => GetMoviesUseAdapter  
}
// Auto-wired for ViewModels
```

---

## 💾 Cache & Network Strategy

### Caching Architecture: **Hybrid Disk + Memory**

1. **On-Disk Layer**: AsyncWriteDisk (Realm) - persistent storage with key-value mapping
2. **Memory Layer**: Dictionary-backed cache (fast, eviction policies via Combine/Publisher)

### Backoff & Rate Limiting

TMDB API uses rate limits (~60 req/min). Implement exponential backoff:

```swift
class RateLimiter {
    var maxRate = 60 // min req per minute
    func getDelay(for retryCount: Int) -> Double {
        let initialDelay = 1.0
        return initialDelay.expontialDouble(at: 2, withMultiplier: 1.5)
    }
}
```

---

## 🧩 MVVM Pattern Details (Presentation Layer Only)

### ViewModel Structure (`MovieDiscoveryViewModel.swift`):

```swift
import Combine
    
class MovieDiscoveryViewModel: ObservableObject {
    // State properties + publishing channels
    @Published var movies: [Movie] = []  
    @Published var searchResults: [MovieSearchResult] = []
    @Published var loading: Bool = false 
    @Published var errorMessage: String?
    
    // View property - optional external data source
    var searchText: String {
        didSet { 
            performSearch() // Trigger UI event  
        }
    }
    
    // Private dependencies (injectable via DI)
    private let apiRepository: APIRepositoryProtocol<Movie, TVShow>
    private let cleanUseCase: GetMoviesUseCase<QueryType, ResultType>
    
    init(viewModelDependencies: ViewModelDependencies) {
        self.apiRepository = viewModelDependencies.apiRepo
        self.cleanUseCase = viewModelDependencies.useCases.useCase
    }
}
```

---

## 🧪 Testing Strategy (85%+ Coverage Target)

### Domain Layer - 100% Coverage (No Test Dependencies)
```swift
// Pure Use Case Unit Tests
class GetMoviesTests {
    func test_searchWithNoResults() throws {
        let result = try await executeTest { 
            // mock inputs  
        }.get().value
        // verify expected output
    }
}
```

### API Layer - Integration + Mock Tests
```swift
// Network layer with mocked HTTP client  
struct MockTVAPIClient: TVRepositoryProtocol {
    // return pre-baked JSON for determinism
}
```

### Presentation Layer - UI Automation Tests
```swift
class MovieDiscoveryViewTests {
    func test_displayLoadedMovies() throws {
        await TestEnvironment.run {
            let view = MovieDiscoveryView(state: .loading)
            // assert UI state
        }
    }
}
```

---

## 🦅 Clippy Type Safety & SwiftLint Rules

### SwiftLint Config (`.swiftlint.yml`):

```yaml
rules:
  strict: true
  cyclomatic_complexity: 
    warning: 15
    error: 20
  nesting:
    warning: 4
    error: 5
  line_length:
    warning: 79
    error: 100  
  force_unwrapping: true
  anyobject_as_any: true
```

### Clippy Config (`Clippy-check.toml`):

```toml
[check]
# Enforce structural type systems for DI protocols
require_all_fields = true   
# No Any/AnyObject in Domain or Application layer  
allow_any_in_domain = false
# All entities must be Value Types (inmutable + Equatable)  
requires_value_types = true
# Type safety check only when compiling 
strict_type_checks = true
```

---

## 📦 Module Interfaces

### Common Interface Contracts:

#### 1. Entities API

```swift
// sampletv-domain-swift-package/Sources/Entities/Movie.swift

struct Movie {
    let id: Int
    let title: String
    let year: Int
    let genres: [Genre]
    let rating: Double?
    
    // Must conform to Codable + Equatable + Hashable
}

extension Movie: Codable {}  
extension Movie: Equatable, Hashable {}
```

#### 2. Repository API

```swift
// sampletv-api-swift-package/Sources/APIProtocols.swift

protocol MovieRepositoryProtocol {
    func fetchMovies(query: String) async throws -> [Movie]
}
```

#### 3. Repository Implementation Contract (API Layer)

```swift
class TMDBClientImpl: MovieRepositoryProtocol {
    // No direct entity access, only protocol types!
    func fetchMovies(query: String) async throws -> [Movie] { 
        // Network call → Map to Entity via DTOs
    }
}
```

#### 4. UseCase Interface (Domain Layer)

```swift
// sampletv-domain-swift-package/Sources/UseCases/GetMovies.swift

protocol GetMoviesUseCaseProtocol {
    func execute(query: String) throws -> [Movie]  
}

// Implementation in Domain - pure Swift
struct GetMoviesImplementation: GetMoviesUseCaseProtocol {
    func execute(query: String) throws -> [Movie] {
        return movies.filter { title.contains(query) }
    }
}
```

---

## 🔄 Git Branching Strategy

### Phase-Based Approach:
```bash
# Initial branch (feature branches only - no direct main commits)
git checkout -b feature/phase_01_foundation  
# ... implement phase ...
git commit -m "feat(phase01): Foundation with DI container and SPM structure"  
git push origin feature/phase_01_foundation

# Phase 2 (branch creation triggers merge to main or rebase onto main)
git checkout feature/phase_02_api_layer
# ... implement phase ...
git commit -m "feat(phase02): TMDB API layer with caching"  
# Push & request pull from origin/main
```

---

*This architecture document defines the blueprint for all code generation and validation across SampleTV.*
