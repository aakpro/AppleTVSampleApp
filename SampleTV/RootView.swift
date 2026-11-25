import SampleTVAuth
import SampleTVDiscovery
import SampleTVDomain
import SampleTVPlayer
import SampleTVProfile
import SampleTVSearch
import SwiftUI

private struct CategoryDestination: Hashable {
    let kind: MediaKind
    let genre: Genre?
}

struct RootView: View {
    let container: AppContainer
    @State private var selection: MediaItem?
    @State private var authenticatedAccount: UserAccount?
    @State private var categoryDestination: CategoryDestination?
    @State private var playingResource: PlayableResource?

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
                    description: Text(
                        "Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and add your token."
                    )
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
                CategoriesView(
                    getGenres: GetGenres(repository: container.repository),
                    onSelectCategory: { kind, genre in
                        categoryDestination = CategoryDestination(kind: kind, genre: genre)
                    },
                    onSelectKind: { kind in
                        categoryDestination = CategoryDestination(kind: kind, genre: nil)
                    }
                )
                .navigationDestination(item: $categoryDestination) { destination in
                    CategoryResultsView(
                        discover: DiscoverMedia(repository: container.repository),
                        kind: destination.kind,
                        genre: destination.genre
                    ) { selection = $0 }
                }
            }
            .tabItem { Label("Categories", systemImage: "list.bullet") }

            NavigationStack {
                SearchView(viewModel: container.makeSearchViewModel()) { selection = $0 }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                ProfileView(viewModel: container.makeProfileViewModel(onSignOut: {
                    selection = nil
                    authenticatedAccount = nil
                }))
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .fullScreenCover(item: $selection) { item in
            DetailsScreen(container: container, item: item)
        }
        .fullScreenCover(item: $playingResource) { resource in
            PlayerScreen(container: container, resource: resource)
        }
    }
}

/// Details plus the player cover. Presented from the app target so features never import each other.
private struct DetailsScreen: View {
    let container: AppContainer
    let item: MediaItem
    @State private var playingResource: PlayableResource?

    var body: some View {
        DetailsView(viewModel: container.makeDetailsViewModel(for: item)) { item in
            Task {
                // Get the playable resource for this item
                if let resource = try? await container.makeDetailsViewModel(for: item).resolvePlayableResource(kind: .feature) {
                    playingResource = resource
                }
            }
        } onSelectRecommendation: { recommendation in
            // Navigate to the recommendation details
            selection = recommendation
        }
        .fullScreenCover(item: $playingResource) { resource in
            PlayerScreen(container: container, resource: resource)
        }
    }
}

private struct PlayerScreen: View {
    let container: AppContainer
    let resource: PlayableResource
    @State private var initialPosition: TimeInterval?
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                PlayerView(
                    url: resource.url,
                    title: resource.title,
                    subtitle: resource.subtitle,
                    initialPosition: initialPosition
                ) { position, duration in
                    // Only save progress if trackProgress is true
                    if resource.trackProgress {
                        let progress = PlaybackProgress(
                            mediaID: resource.id ?? MediaID(kind: .movie, value: 0), // We need to handle this better
                            position: position,
                            duration: duration
                        )
                        Task {
                            try? await container.progressStore.saveProgress(progress)
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            // Only load saved progress if trackProgress is true
            if resource.trackProgress {
                let saved = try? await container.progressStore.loadProgress(for: resource.id ?? MediaID(kind: .movie, value: 0))
                if let saved, !saved.isWatched {
                    initialPosition = saved.position
                }
            }
            isReady = true
        }
    }
}
