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
            .frame(maxWidth: 420)

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
        .padding(.horizontal, 60)
    }

    @ViewBuilder
    private var results: some View {
        switch viewModel.state {
        case .idle:
            ContentUnavailableView("Search Movies and Shows", systemImage: "magnifyingglass")
        case .failed:
            ContentUnavailableView("Search Failed", systemImage: "exclamationmark.triangle")
        case .loaded(let items) where items.isEmpty:
            ContentUnavailableView.search(text: viewModel.text)
        case .loaded(let items):
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 40)], spacing: 60) {
                    ForEach(items) { item in
                        Button { onSelect(item) } label: { MediaCard(item: item) }
                            .buttonStyle(.card)
                            .task {
                                if item == items.last, viewModel.canLoadMore {
                                    await viewModel.loadNextPage()
                                }
                            }
                    }
                }
                .padding(60)
            }
        }
    }
}
