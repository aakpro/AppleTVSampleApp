import SampleTVDiscovery
import SampleTVSearch
import SampleTVDomain
import SwiftUI

struct RootView: View {
    let container: AppContainer
    @State private var selection: MediaItem?

    var body: some View {
        if container.configuration.hasToken {
            TabView {
                NavigationStack {
                    DiscoveryView(viewModel: container.makeDiscoveryViewModel()) { selection = $0 }
                        .navigationTitle("Discover")
                }
                .tabItem {
                    Label("Discover", systemImage: "tv")
                }
                
                NavigationStack {
                    SearchView(viewModel: container.makeSearchViewModel()) { selection = $0 }
                        .navigationTitle("Search")
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
            }
            .fullScreenCover(item: $selection) { item in
                DetailsView(viewModel: container.makeDetailsViewModel(for: item)) { _ in
                    // Play action wired in Phase 6
                }
            }
        } else {
            ContentUnavailableView(
                "TMDB token missing",
                systemImage: "key.slash",
                description: Text("Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and add your token.")
            )
        }
    }
}
