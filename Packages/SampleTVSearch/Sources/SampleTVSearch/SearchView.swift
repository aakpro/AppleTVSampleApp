import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let onSelect: (MediaItem) -> Void

    public init(viewModel: SearchViewModel, onSelect: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    private struct Key: Equatable {
        let text: String
        let selectedKind: MediaKind?
        let filter: MediaFilter
    }

    public var body: some View {
        VStack(spacing: 24) {
            filterBar
            results
        }
        .searchable(text: $viewModel.text)
        .task(id: viewModel.selectedKind) {
            await viewModel.loadGenres()
        }
        .task(id: Key(text: viewModel.text, selectedKind: viewModel.selectedKind, filter: viewModel.filter)) {
            await viewModel.performSearch()
        }
    }

    private var filterBar: some View {
        HStack(spacing: 24) {
            Picker("Type", selection: $viewModel.selectedKind) {
                Text("All").tag(MediaKind?.none)
                Text("Movies").tag(MediaKind?.some(.movie))
                Text("TV Shows").tag(MediaKind?.some(.tv))
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .accessibilityIdentifier("search.kindPicker")

            if !viewModel.availableGenres.isEmpty {
                Menu {
                    Button("All Genres") {
                        viewModel.filter.genreIDs = []
                    }
                    ForEach(viewModel.availableGenres) { genre in
                        Button(genre.name) {
                            viewModel.filter.genreIDs = [genre.id]
                        }
                    }
                } label: {
                    let selectedName = viewModel.availableGenres
                        .first { viewModel.filter.genreIDs.contains($0.id) }?.name ?? "All Genres"
                    Label(selectedName, systemImage: "line.3.horizontal.decrease.circle")
                }
            }

            Spacer()
        }
        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search Movies and Shows", systemImage: "magnifyingglass")
        case .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorView(error: error) { Task { await viewModel.retry() } }
        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView.search(text: viewModel.text)
        case .loaded(let items):
            let columns = [
                GridItem(
                    .adaptive(minimum: SampleTVTheme.cardWidth, maximum: SampleTVTheme.cardWidth),
                    spacing: SampleTVTheme.shelfItemSpacing
                )
            ]
            ScrollView {
                LazyVGrid(columns: columns, spacing: 44) {
                    ForEach(items) { item in
                        MediaCard(item: item) {
                            onSelect(item)
                        }
                        .task {
                            if item == items.last, viewModel.canLoadMore {
                                await viewModel.loadNextPage()
                            }
                        }
                    }
                }
                .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
                .padding(.vertical, 36)
            }
            .scrollClipDisabled()
        }
    }
}
