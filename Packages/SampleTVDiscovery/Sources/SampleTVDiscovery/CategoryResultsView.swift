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

    private var headerTitle: String {
        viewModel.genre?.name ?? (viewModel.kind == .movie ? "All Movies" : "All TV Shows")
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            content
        }
        .task(id: viewModel.sort) { await viewModel.reload() }
    }

    private var header: some View {
        HStack(spacing: 24) {
            Text(headerTitle)
                .font(SampleTVTheme.Typography.screenTitle)

            Spacer()

            Picker("Sort", selection: $viewModel.sort) {
                Text("Popular").tag(MediaSort.popularity)
                Text("Top Rated").tag(MediaSort.rating)
                Text("Newest").tag(MediaSort.newest)
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .accessibilityIdentifier("categories.sortPicker")
        }
        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            if viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                grid
            }
        case .failed(let error) where viewModel.items.isEmpty:
            ErrorView(error: error) { Task { await viewModel.reload() } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            VStack(spacing: 32) {
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

                if viewModel.isLoadingNextPage {
                    ProgressView()
                        .padding(.vertical, 16)
                }
            }
            .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
            .padding(.vertical, 28)
        }
        .scrollClipDisabled()
    }
}
