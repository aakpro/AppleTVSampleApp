import SampleTVDomain
import SampleTVUI
import SwiftUI

struct WatchlistSection: View {
    let viewModel: ProfileViewModel
    let onSelectItem: ((MediaItem) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My List")
                .font(.headline)

            if viewModel.watchlistItems.isEmpty {
                Text("No saved titles yet.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 40) {
                        ForEach(viewModel.watchlistItems) { item in
                            Button {
                                onSelectItem?(item)
                            } label: {
                                MediaCard(item: item)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }
        }
    }
}
