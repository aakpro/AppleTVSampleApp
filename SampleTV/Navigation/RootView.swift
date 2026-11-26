import SampleTVAuth
import SampleTVDiscovery
import SampleTVDomain
import SampleTVProfile
import SampleTVSearch
import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var viewModel: RootViewModel

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: container.makeRootViewModel())
    }

    var body: some View {
        Group {
            if viewModel.authenticatedAccount != nil {
                tabs
            } else if viewModel.hasTMDBToken {
                LoginView(viewModel: container.makeLoginViewModel { account in
                    Task { await viewModel.didAuthenticate(account) }
                })
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
            await viewModel.loadSession()
        }
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                DiscoveryView(viewModel: container.makeDiscoveryViewModel()) { item in
                    Task { await viewModel.selectMedia(item) }
                }
            }
            .tabItem { Label("Discover", systemImage: "square.grid.2x2") }

            NavigationStack {
                CategoriesView(
                    viewModel: container.makeCategoriesViewModel(),
                    onSelectCategory: { kind, genre in
                        viewModel.selectCategory(kind: kind, genre: genre)
                    },
                    onSelectKind: { kind in
                        viewModel.selectCategory(kind: kind, genre: nil)
                    }
                )
                .navigationDestination(item: $viewModel.categoryDestination) { destination in
                    CategoryResultsView(
                        viewModel: container.makeCategoryResultsViewModel(
                            kind: destination.kind,
                            genre: destination.genre
                        )
                    ) { item in
                        Task { await viewModel.selectMedia(item) }
                    }
                }
            }
            .tabItem { Label("Categories", systemImage: "list.bullet") }

            NavigationStack {
                SearchView(viewModel: container.makeSearchViewModel()) { item in
                    Task { await viewModel.selectMedia(item) }
                }
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                ProfileView(
                    viewModel: container.makeProfileViewModel {
                        viewModel.signOut()
                    },
                    onSelectItem: { item in
                        Task { await viewModel.selectMedia(item) }
                    }
                )
            }
            .tabItem { Label("Profile", systemImage: "person.circle") }
        }
        .fullScreenCover(item: $viewModel.selection) { item in
            DetailsScreen(container: container, item: item, profileID: viewModel.activeProfileID) { recommended in
                Task { await viewModel.selectMedia(recommended) }
            }
            .id(item.id)
        }
    }
}
