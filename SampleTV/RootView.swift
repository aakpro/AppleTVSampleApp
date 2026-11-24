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
    
    init(container: AppContainer, item: MediaItem) {
        self.container = container
        self.item = item
    }

    var body: some View {
        DetailsView(viewModel: container.makeDetailsViewModel(for: item)) { playing = $0 }
            .fullScreenCover(item: $playing) { item in
                Task {
                    let progress = try? await container.progressStore.loadProgress(for: item.id)
                    let initialPosition = progress?.position
                    PlayerView(url: container.playbackURL(for: item), initialPosition: initialPosition)
                }
            }
    }
}
