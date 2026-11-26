import SampleTVDomain
import SampleTVUI
import SwiftUI

struct WatchlistSection: View {
    let viewModel: ProfileViewModel
    let onSelectItem: ((MediaItem) -> Void)?

    var body: some View {
        if viewModel.watchlistItems.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("My List")
                    .font(.headline)

                Text("No saved titles yet.")
                    .foregroundStyle(.secondary)
            }
        } else {
            MediaShelfRow(
                title: "My List",
                items: viewModel.watchlistItems,
                horizontalMargin: 0
            ) { item in
                onSelectItem?(item)
            }
        }
    }
}
