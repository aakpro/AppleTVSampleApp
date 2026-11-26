import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct CategoryResultsView: View {
    @State private var viewModel: CategoryResultsViewModel
    private let onSelect: (MediaItem) -> Void

    public init(
        viewModel: CategoryResultsViewModel,
        onSelect: @escaping (MediaItem) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    public var body: some View {
        content
            .navigationTitle(viewModel.genre?.name ?? (viewModel.kind == .movie ? "All Movies" : "All TV Shows"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Sort", selection: $viewModel.sort) {
                        Text("Popular").tag(MediaSort.popularity)
                        Text("Top Rated").tag(MediaSort.rating)
                        Text("Newest").tag(MediaSort.newest)
                    }
                }
            }
            .task(id: viewModel.sort) { await viewModel.reload() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            if viewModel.items.isEmpty {
                ProgressView()
            } else {
                grid
            }
        case .failed(let error) where viewModel.items.isEmpty:
            ErrorView(error: error) { Task { await viewModel.reload() } }
        case .loaded, .failed:
            grid
        }
    }

    private var grid: some View {
        let columns = [
            GridItem(
                .adaptive(minimum: SampleTVTheme.cardWidth, maximum: SampleTVTheme.cardWidth),
                spacing: SampleTVTheme.shelfItemSpacing
            )
        ]
        return ScrollView {
            LazyVGrid(columns: columns, spacing: 44) {
                ForEach(viewModel.items) { item in
                    MediaCard(item: item) {
                        onSelect(item)
                    }
                    .task {
                        if item == viewModel.items.last, viewModel.canLoadMore {
                            await viewModel.loadNextPage()
                        }
                    }
                }
            }
            .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
            .padding(.vertical, 40)
        }
        .scrollClipDisabled()
    }
}
