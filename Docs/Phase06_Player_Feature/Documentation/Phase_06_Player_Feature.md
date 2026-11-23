# Phase 6: Player

| | |
|---|---|
| Branch | `feature/phase_06_player_feature` |
| Depends on | Phases 1-5 |
| Delivers | `SampleTVPlayer` (AVKit playback), the Play button wired end to end, and the final app composition |

## What "video" means here

TMDB provides **metadata only**. Its `videos` endpoint returns YouTube/Vimeo keys that `AVPlayer` cannot play. So the
app plays one public sample HLS stream for every title. The seam is `AppContainer.playbackURL(for:)`: a real catalogue
would replace its body, nothing else.

Sample stream (Apple's public bipbop example, HTTP 200 when checked):
`https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8`

## Deliverables

```
Packages/SampleTVPlayer/
├── Package.swift                      no dependencies
└── Sources/SampleTVPlayer/PlayerView.swift

SampleTV/AppContainer.swift            final composition (below)
SampleTV/RootView.swift                tabs, details cover, player cover
SampleTV/SampleTVApp.swift             unchanged from Phase 1
```

## Design

- **Use the system player.** `VideoPlayer` (AVKit) on tvOS provides transport controls, scrubbing, audio/subtitle pickers,
  and Siri Remote handling. Earlier drafts planned a custom timeline, volume slider and buffering UI; tvOS apps have no
  volume control and the native UI already does all of this. Do not rebuild it.
- **No Domain dependency.** `PlayerView(url:)` takes a `URL`. The app resolves the URL from the selected item, so the
  player package stays tiny and reusable.
- **Failure handling.** `AVPlayerItem.status` flips to `.failed` for bad URLs, network errors and unsupported media.
  The view observes it through KVO and shows a message (`item.error`). Observation uses `publisher(for:)` because the
  newer `Observations` API requires a newer OS than the packages' minimum.
- **Lifecycle.** Play on appear, pause on disappear. On tvOS the Menu button dismisses the full-screen cover.
- **Navigation ownership.** `RootView` presents details from either tab, and details present the player. Feature
  packages never import each other; the app target connects them.

## Steps

1. Branch; create `SampleTVPlayer`; add it with **Add Local…**; link it to the app target.
2. Add `PlayerView.swift`.
3. Replace `AppContainer` and `RootView` with the final versions below (they include everything from Phases 3-5).
4. Test on the simulator: open a title, press Play, the stream starts; press Menu to return.
5. Stretch goals (only after the above is solid): resume position stored behind a Domain protocol
   (`PlaybackProgressStore`, `UserDefaults` or SwiftData implementation); "Continue Watching" row.

## Code

**`Packages/SampleTVPlayer/Package.swift`**

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SampleTVPlayer",
    platforms: [.tvOS(.v17)],
    products: [
        .library(name: "SampleTVPlayer", targets: ["SampleTVPlayer"])
    ],
    targets: [
        .target(name: "SampleTVPlayer")
    ]
)
```

**`Packages/SampleTVPlayer/Sources/SampleTVPlayer/PlayerView.swift`**

```swift
import AVKit
import Combine
import SwiftUI

/// Thin wrapper over the system player. tvOS already provides transport controls, scrubbing,
/// audio/subtitle pickers and Siri Remote handling; don't rebuild them.
public struct PlayerView: View {
    private let url: URL
    @State private var player: AVPlayer
    @State private var failure: String?

    public init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    public var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .overlay {
                if let failure {
                    ContentUnavailableView(
                        "Playback Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(failure)
                    )
                }
            }
            .task { await observeStatus() }
            .onAppear { player.play() }
            .onDisappear { player.pause() }
    }

    /// `AVPlayerItem.status` flips to `.failed` for bad URLs, DRM and network errors.
    private func observeStatus() async {
        guard let item = player.currentItem else { return }
        for await status in item.publisher(for: \.status).values where status == .failed {
            failure = item.error?.localizedDescription ?? "Unknown error"
            return
        }
    }
}
```

### Final app composition

**`SampleTV/AppContainer.swift`**

```swift
import Foundation
import SampleTVAPI
import SampleTVDiscovery
import SampleTVDomain
import SampleTVSearch

@MainActor
final class AppContainer {
    /// Public Apple test stream. TMDB provides metadata only, never video.
    static let sampleStream = URL(
        string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    )!

    let configuration: AppConfiguration
    let repository: any MediaRepository

    init(configuration: AppConfiguration, repository: any MediaRepository) {
        self.configuration = configuration
        self.repository = repository
    }

    static func live() -> AppContainer {
        let configuration = AppConfiguration()
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: configuration.tmdbToken),
            transport: URLSession.tmdbCached()
        )
        return AppContainer(configuration: configuration, repository: TMDBMediaRepository(client: client))
    }

    func makeDiscoveryViewModel() -> DiscoveryViewModel {
        DiscoveryViewModel(discover: DiscoverMedia(repository: repository))
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(search: SearchMedia(repository: repository))
    }

    func makeDetailsViewModel(for item: MediaItem) -> DetailsViewModel {
        DetailsViewModel(item: item, getDetails: GetMediaDetails(repository: repository))
    }

    /// Seam for a real catalogue: map a title to its stream. Always the sample stream for now.
    func playbackURL(for item: MediaItem) -> URL {
        Self.sampleStream
    }
}
```

**`SampleTV/RootView.swift`**

```swift
import SampleTVDiscovery
import SampleTVDomain
import SampleTVPlayer
import SampleTVSearch
import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var selection: MediaItem?

    var body: some View {
        if container.configuration.hasToken {
            tabs
        } else {
            ContentUnavailableView(
                "TMDB token missing",
                systemImage: "key.slash",
                description: Text("Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and add your token.")
            )
        }
    }

    private var tabs: some View {
        TabView {
            Tab("Discover", systemImage: "square.grid.2x2") {
                NavigationStack {
                    DiscoveryView(viewModel: container.makeDiscoveryViewModel()) { selection = $0 }
                        .navigationTitle("Discover")
                }
            }
            Tab("Search", systemImage: "magnifyingglass", role: .search) {
                NavigationStack {
                    SearchView(viewModel: container.makeSearchViewModel()) { selection = $0 }
                }
            }
        }
        .fullScreenCover(item: $selection) { item in
            DetailsScreen(container: container, item: item)
        }
    }
}

/// Details plus the player cover. Presented from the app target so features never import each other.
private struct DetailsScreen: View {
    let container: AppContainer
    let item: MediaItem
    @State private var playing: MediaItem?

    var body: some View {
        DetailsView(viewModel: container.makeDetailsViewModel(for: item)) { playing = $0 }
            .fullScreenCover(item: $playing) { item in
                PlayerView(url: container.playbackURL(for: item))
            }
    }
}
```

These two files, together with `PlayerView`, the Domain, API, UI, Discovery and Search packages, were built
together in Swift 6 mode against the tvOS simulator SDK. `AppConfiguration` and `SampleTVApp` are unchanged from Phase 1.

## Tests

- **Unit**: `AppContainer.playbackURL(for:)` returns the sample stream; add a test through a stub repository.
- **UI smoke test**: launch with the stub-repository launch argument from Phase 4, select a title, press Play, assert the
  player's presence (for example `app.otherElements["PlayerView"]` after adding `.accessibilityIdentifier("PlayerView")`)
  and that no "Playback Failed" text appears. Do not assert on video frames.
- `PlayerView` itself is covered by the smoke test and the manual check; there is no useful pure logic to unit test.

## Verify

```bash
cd Packages/SampleTVPlayer && xcodebuild build -scheme SampleTVPlayer -destination "id=$UDID"
cd ../.. && xcodebuild test -scheme SampleTV -destination "id=$UDID"
swiftlint lint --quiet | grep -c "error:"              # 0
curl -sI "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8" | head -1
```

Manual: play, pause, scrub, leave and re-enter; then set an invalid URL temporarily and confirm "Playback Failed" appears
instead of a black screen.

## Definition of done

- [ ] Selecting a title and pressing Play streams the sample video; Menu returns to details.
- [ ] A failing stream shows a message, not a blank screen or crash.
- [ ] All six packages build, all tests pass, lint has no errors, CI is green.
- [ ] README roadmap, status table and `CHANGELOG.md` updated; the app is ready for the `v1.0.0` release process.

## After Phase 6

Release per [RELEASE_PROCESS.md](../../RELEASE_PROCESS.md). Ideas that are explicitly out of scope until requested: user
accounts, a real streaming backend, downloads, SwiftData-backed watchlist.
