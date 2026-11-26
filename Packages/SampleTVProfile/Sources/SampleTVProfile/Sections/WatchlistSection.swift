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
                    .font(SampleTVTheme.Typography.sectionTitle)

                Text("No saved titles yet.")
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
        } else {
            MediaShelfRow(
                title: "My List",
                items: viewModel.watchlistItems,
                horizontalMargin: SampleTVTheme.horizontalSafeMargin
            ) { item in
                onSelectItem?(item)
            }
        }
    }
}
