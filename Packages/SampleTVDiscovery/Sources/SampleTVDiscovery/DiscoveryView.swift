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
            .task(id: viewModel.filter) {
                async let reloadTask: Void = viewModel.reload()
                async let continueTask: Void = viewModel.loadContinueWatching()
                _ = await (reloadTask, continueTask)
            }
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
                VStack(alignment: .leading, spacing: 40) {
                    if !viewModel.continueWatchingItems.isEmpty {
                        SectionHeader(title: "Continue Watching")
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 40) {
                                ForEach(viewModel.continueWatchingItems) { item in
                                    Button { onSelect(item) } label: {
                                        MediaCard(item: item)
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                        }
                    }

                    SectionHeader(title: "Discover")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 40)], spacing: 60) {
                        ForEach(items) { item in
                            Button { onSelect(item) } label: {
                                MediaCard(item: item)
                            }
                            .buttonStyle(.card)
                            .task {
                                if item == items.last, viewModel.canLoadMore {
                                    await viewModel.loadNextPage()
                                }
                            }
                        }
                    }
                }
                .padding(60)
            }
        }
    }
}

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundStyle(.primary)
    }
}
