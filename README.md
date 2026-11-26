# SampleTV

SampleTV is a tvOS app built using the clean architecture approach with Swift. This project implements features in phases, each building upon the previous ones to create a comprehensive media discovery and playback application.

## Getting Started

To get started with this project, you'll need:
- Xcode 15+ (with tvOS support)
- A TMDB API token for access to movie/series data

### Setting Up Your Environment

1. Get a [TMDB API token](https://www.themoviedb.org/settings/api) 
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig`
3. Add your TMDB token to the new `Secrets.xcconfig` file

### Building and Running

```bash
# Set up simulator device (Apple TV)
UDID=$(xcrun simctl list devices available -j \
  | jq -r '[.devices[][] | select(.name | startswith("Apple TV"))][0].udid')

# Build app
xcodebuild build -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID"

# Test app (skipping UI tests)
xcodebuild test -workspace SampleTV.xcworkspace -scheme SampleTV -destination "id=$UDID" -skip-testing:SampleTVUITests
```

### Project Structure

The project is organized into multiple Swift packages following clean architecture principles:

- **Packages/**
  - `SampleTVDomain` - Core domain logic and types (Foundation only)
  - `SampleTVAPI` - Data layer for interacting with TMDB API
  - `SampleTVUI` - UI components, helpers, and error handling
  - `SampleTVDiscovery` - Media discovery features (Search, Categories, etc.)
  - `SampleTVAuth` - Authentication related functionality
  - `SampleTVProfile` - User profiles and preferences
  - `SampleTVPlayer` - Video playback functionality

- **SampleTV/** - App target with the main application logic

## Architecture Rules

1. **Dependency Direction**:
   - `SampleTVDomain` imports Foundation only
   - All other packages depend on `SampleTVDomain`
   - Only app target sees every package

2. **Ports and Adapters**:
   - Domain defines interfaces (`MediaRepository`, etc.)
   - API implements them
   - View models use protocols, never concrete implementations

3. **DTOs**:
   - Keep in `SampleTVAPI`
   - Map to domain entities at the boundary

4. **DI**:
   - Constructor injection from `AppContainer` in app target

5. **Concurrency**:
   - Swift 6 language mode
   - View models are `@MainActor @Observable final class`  
   - Models are `Sendable` value types
   - Use `async/await`; avoid Combine or completion handlers

## Phase Status

- ⚙️ Phase 01: Setup and Configuration (Complete)
- ⚙️ Phase 02: Basic Domain, API, and Error Handling (Complete)  
- ⚙️ Phase 03: Data Layer with Pagination (Complete)
- 🔧 Phase 03b: Stabilization (Complete)
- 📺 Phase 04: Movie Discovery UI (`SampleTVUI`, `SampleTVDiscovery`) (In Progress)
- 📺 Phase 05: Search and Categories UI (`SampleTVSearch`, `SampleTVDiscovery`) (In Progress)
- 📺 Phase 06: Profile Management UI (`SampleTVProfile`) (In Progress)
- 📺 Phase 07: Authentication UI (`SampleTVAuth`) (In Progress)
- 📺 Phase 08: Playback UI and Player (`SampleTVPlayer`) (In Progress)
- 📺 Phase 09: Settings, Preferences, and Watchlist Features (In Progress)
- 📺 Phase 10: Trailer and Metadata Handling (In Progress)
- 📺 Phase 11: Continue Watching and Progress Tracking (In Progress)
- 📺 Phase 12: Multi-profile Support (In Progress)
- 📺 Phase 13: Dark Mode, Customization, and Themes (In Progress)
- ⚙️ Phase 14: App Composition and Refactoring (Complete)

## Contributing

Issues and pull requests are welcome! Please ensure your code follows SwiftLint rules.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.