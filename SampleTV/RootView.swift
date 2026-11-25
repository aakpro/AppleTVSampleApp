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

private struct PlaybackSelection: Identifiable {
    let id = UUID()
    let mediaID: MediaID
    let resource: PlayableResource
}

struct RootView: View {
    let container: AppContainer
    @State private var selection: MediaItem?
    @State private var authenticatedAccount: UserAccount?
    @State private var categoryDestination: CategoryDestination?
    @State private var activeProfileID = "main"

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
            if let account = await container.authRepository.currentAccount() {
                authenticatedAccount = account
            }
        }
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                DiscoveryView(viewModel: container.makeDiscoveryViewModel()) { selectMedia($0) }
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
                    ) { selectMedia($0) }
                }
            }
            .tabItem { Label("Categories", systemImage: "list.bullet") }

            NavigationStack {
                SearchView(viewModel: container.makeSearchViewModel()) { selectMedia($0) }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                ProfileView(viewModel: container.makeProfileViewModel(onSignOut: {
                    selection = nil
                    categoryDestination = nil
                    authenticatedAccount = nil
                }), onSelectItem: { selectMedia($0) })
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .fullScreenCover(item: $selection) { item in
            DetailsScreen(container: container, item: item, profileID: activeProfileID) { recommended in
                selection = recommended
            }
            .id(item.id)
        }
        .task {
            await refreshActiveProfileID()
        }
    }

    private func refreshActiveProfileID() async {
        do {
            let profile = try await container.profileRepository.currentProfile()
            activeProfileID = profile.id
        } catch {
            activeProfileID = "main"
        }
    }

    private func selectMedia(_ item: MediaItem) {
        Task {
            await refreshActiveProfileID()
            selection = item
        }
    }
}

/// Details plus the player cover. Presented from the app target so features never import each other.
private struct DetailsScreen: View {
    let container: AppContainer
    let item: MediaItem
    let profileID: String
    let onSelectRecommendation: (MediaItem) -> Void
    @State private var playbackSelection: PlaybackSelection?

    var body: some View {
        DetailsView(
            viewModel: container.makeDetailsViewModel(for: item, profileID: profileID),
            onPlay: { item in
                Task { await startPlayback(for: item, kind: .feature) }
            },
            onPlayTrailer: { item in
                Task { await startPlayback(for: item, kind: .trailer) }
            },
            onSelectRecommendation: onSelectRecommendation
        )
        .fullScreenCover(item: $playbackSelection) { selection in
            PlayerScreen(container: container, selection: selection)
        }
    }

    private func startPlayback(for item: MediaItem, kind: PlaybackResourceKind) async {
        let resources = (try? await container.resourceResolver.resolve(item.id, genreIDs: item.genreIDs)) ?? []
        let resolved = resources.first { $0.kind == kind } ?? PlayableResource(
            url: container.playbackURL(for: item),
            kind: kind,
            title: item.title,
            trackProgress: kind == .feature
        )
        playbackSelection = PlaybackSelection(mediaID: item.id, resource: resolved)
    }
}

private struct PlayerScreen: View {
    let container: AppContainer
    let selection: PlaybackSelection
    @State private var initialPosition: TimeInterval?
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                PlayerView(
                    url: selection.resource.url,
                    title: selection.resource.title,
                    subtitle: selection.resource.subtitle,
                    initialPosition: initialPosition
                ) { position, duration in
                    guard selection.resource.trackProgress else { return }
                    let progress = PlaybackProgress(
                        mediaID: selection.mediaID,
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
            if selection.resource.trackProgress {
                let saved = try? await container.progressStore.loadProgress(for: selection.mediaID)
                if let saved, !saved.isWatched {
                    initialPosition = saved.position
                }
            }
            isReady = true
        }
    }
}
