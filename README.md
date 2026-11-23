# SampleTV - Apple TV+ Style Video Streaming App

> ⚡ **Project Overview**: A top-tier software engineering demonstration of a premium video streaming application built with Clean Architecture principles and enterprise-grade Swift ecosystem. Focused exclusively on content playback functionality inspired by Apple TV+.

---

## 🎯 Project Philosophy

This project embodies the highest standards of iOS development:
1. **Clean Architecture** - Enterprise, Domain, Presentation layers
2. **MVVM in Presentation Layer** - ViewModels with business logic separation
3. **Dependency Injection** - Structural conformances + Application-wide DI container (SwiftInject)
4. **Feature-Based Local SPMs** - Modularized codebases per feature
5. **Version Control Excellence** - Full GitHub workflow with PR reviews and release tags

---

## 🏗️ Architecture Design

### Vertical Slicing (Horizontal Layers):
```
┌─────────────────────────────────────┐
│     PRESENTATION LAYER              │
│  ┌─────────┐ ┌───────────┐         │
│  │ Views   │ │ ViewModels │       │
│  ↓          ↓              │        │
├───────────────────────────────────┤
│      DOMAIN LAYER (No Dependencies)│
│  ┌──────────────────────────────┐ │
│  │     Entities & Use Cases     │ │
│  └──────────────────────────────┘ │
│         ↓                           │
├───────────────────────────────────┤
│      APPLICATION LAYER             │
│  ┌───────────┐ ┌──────────────┐   │
│  │ Repositories │ Application Services  │   │
│  └───────────┘ └──────────────┘   │
│         ↓                           │
├───────────────────────────────────┤
│      INFRASTRUCTURE LAYER          │
│  ┌───────────┐ ┌──────────────┐   │
│  │ Network    │ Local Storage  │   │
│  └───────────┘ └──────────────┘   │
└─────────────────────────────────────┘
```

### Horizontal Slicing (Feature-Based SPMs):
```
📦 Root Package (SampleTV)
 ├── 🎬 App Library / sampletv.xcodeproj
 │    ├── Application Module
 │    ├── Navigation Layer  
 │    └── Main App Entry Point
 │
 ├── ⚡ API Module / sampletv-api-swift-package
 │    ├── Networking Infrastructure
 │    ├── API Clients
 │    ├── Request Builders
 │    └── Cache Services
 │
 ├── 🏛️ Domain / sampletv-domain-swift-package
 │    ├── Entities Repository
 │    ├── Value Objects  
 │    └── Pure Use Cases (Domain Layer)
 │
 ├── 🎨 Feature: Movie Discovery / sampletv-movie-discovery
 │    ├── ViewModels
 │    ├── View Components  
 │    ├── Repository Abstraction
 │    └── Domain Logic Integration
 │
 ├── 🔍 Feature: Search / sampletv-search-module
 │    ├── Search Query Building
 │    ├── Filtering Logic
 │    └── Result Presentations
 │
 ├── 🎬 Feature: Player / sampletv-player-module
 │    ├── Video Player Implementation
 │    ├── Playback Controls
 │    └── UI Integration
 │
 └── ⚙️ Utilities / sampletv-utils
     └── Shared helpers, extensions
```

---

## 🔄 Git Workflow (GitHub Flow)

### Standard Process:
1. **Feature Branch Creation**: `git checkout -b feature/00_api_layer`
2. **Implementation Phase**: 
   ```bash
   # Write code
   # Run local tests
   # Commit changes
   git add .
   git commit -m "feat(API): Implement network layer with TMDB endpoints"
   ```
3. **Pull Request Creation**: Open PR to `main` branch
   - Include screenshots, API documentation
   - Add performance benchmarks
   - List all affected files + reason for changes
4. **Code Review Process** (Mandatory):
   - 2 approvers required
   - Performance & correctness reviews
   - Security audit for external dependencies
5. **Merge**: 
   - Squash merge option with descriptive commit message
   - Add to CHANGELOG.md under unreleased section
6. **Release Creation**: Bump version in `Package.swift`
   ```swift
   // Before merge
   // After merge
   ```
7. **Tag & Push Release**: 
   ```bash
   git tag -a v1.0.0 -m "Initial release"
   git push origin v1.0.0
   git push --tags
   ```

---

## 📄 Required Documentation Files

### Root Level:
- `README.md` (Current)
- `CONTRIBUTING.md`
- `ARCHITECTURE.md`
- `RELEASE_PROCESS.md`
- `API_SPECS.md`
- `PR_TEMPLATE.md`

### Domain Layer:
- `DOMAIN/Entities/Movie.swift` 
- `DOMAIN/Entities/Show.swift`
- `DOMAIN/UseCases/{GetMovies, GetDetails, SearchContent}.swift`

### API Module:
- `NETWORKING/APIClients.{Movie,Tv,Search,Details}.swift`
- `CACHING/CacheManager.swift`

---

## 🛠️ Tech Stack

- **Language**: Swift 6 (Concurrency-first)
- **UI**: SwiftUI  
- **Routing**: iOS Navigation Framework 
- **Dependencies Injection**: SwiftInject / Structured Conformances
- **Async/Await**: Combine & async-await hybrid approach
- **Testing**: XCTest, SwiftLint, Clippy checks

---

## 📞 API Integration

### TMDB API Configuration:
```bash
# Your tmdb_api_key will be stored here in .env file
TMDB_API_KEY=your_api_key_here
API_ENDPOINT_BASE=https://api.themoviedb.org/3
```

### Key Endpoints:
- `/discover/tv` - Discover TV content
- `/tv/{id}` - Get show details  
- `/search?api_key=YOURKEY&q=query` - Search
- `/recommendation?id={id}&with_genres=...` - Personalized recommendations

---

## 📧 Open Issues & Questions

1. Should domain use cases include business logic that affects user experience (e.g., rate limiting)?
2. What level of local caching do you expect for offline viewing support?
3. Do we need to handle TMDB API v4 transition?
4. Should each module have its own unit tests or shared test framework?

---

## 🚀 Initial Implementation Roadmap

| Phase | Description | Estimated Time | Target Branch |
|-------|-------------|----------------|---------------|
| 1 | Foundation (DI container, DI services) | 2-3 days | `phase_01_foundation` |
| 2 | TMDB API integration + caching | 5-7 days | `phase_02_api_layer` |
| 3 | Domain layer (Entities, pure use cases) | 3-5 days | `phase_03_domain_layer` |
| 4 | Movie Discovery Feature | 7-10 days | `phase_04_movie_discovery` |
| 5 | Search & Filtering Module | 5-8 days | `phase_05_search_module` |
| 6 | Video Player Implementation | 8-12 days | `phase_06_player_feature` |

---

*Generated with top-tier software engineering principles in mind. All modules strictly type-safe, fully documented, and CI/CD ready.*
