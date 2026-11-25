import SampleTVAuth
import SampleTVDiscovery
import SampleTVDomain
import SampleTVPlayer
import SampleTVSearch
import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var selection: MediaItem?
    @State private var authenticatedAccount: UserAccount?

    var body: some View {
        Group {
            if authenticatedAccount != nil {
                tabs
            } else if container.configuration.hasToken {
                LoginView(viewModel: container.makeLoginViewModel(onAuthenticated: { account in
                    authenticatedAccount = account
                }))
            } else {
                ContentUnavailableView(
                    "TMDB token missing",
                    systemImage: "key.slash",
                    description: Text("Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and add your token.")
                )
            }
        }
        .task {
            // Load current account on launch
            if let account = await container.authRepository.currentAccount() {
                authenticatedAccount = account
            }
        }
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                DiscoveryView(viewModel: container.makeDiscoveryViewModel()) { selection = $0 }
                    .navigationTitle("Discover")
            }
            .tabItem { Label("Discover", systemImage: "square.grid.2x2") }

            NavigationStack {
                SearchView(viewModel: container.makeSearchViewModel()) { selection = $0 }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
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
                PlayerScreen(container: container, item: item)
            }
    }
}

private struct PlayerScreen: View {
    let container: AppContainer
    let item: MediaItem
    @State private var initialPosition: TimeInterval?
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                PlayerView(
                    url: container.playbackURL(for: item),
                    initialPosition: initialPosition
                ) { position, duration in
                    let progress = PlaybackProgress(
                        mediaID: item.id,
                        position: position,
                        duration: duration
                    )
                    Task {
                        try? await container.progressStore.saveProgress(progress)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            let saved = try? await container.progressStore.loadProgress(for: item.id)
            if let saved, !saved.isWatched {
                initialPosition = saved.position
            }
            isReady = true
        }
    }
}
