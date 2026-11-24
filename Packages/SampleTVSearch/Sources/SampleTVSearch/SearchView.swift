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
        let filter: MediaFilter
    }

    public var body: some View {
        results
            .searchable(text: $viewModel.text)
            .task(id: Key(text: viewModel.text, filter: viewModel.filter)) {
                await viewModel.performSearch()
            }
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