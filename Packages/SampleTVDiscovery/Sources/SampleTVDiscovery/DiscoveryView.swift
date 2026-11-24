import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DiscoveryView: View {
    @State private var viewModel: DiscoveryViewModel
    private let onSelect: (MediaItem) -> Void

    public init(viewModel: DiscoveryViewModel, onSelect: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
    }

    public var body: some View {
        content
            .task(id: viewModel.filter) { await viewModel.reload() }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            ErrorView(error: error) { Task { await viewModel.reload() } }
        case .loaded(let items):
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 40)], spacing: 60) {
                    ForEach(items) { item in
                        Button { onSelect(item) } label: { 
                            MediaCard(item: item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
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