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
            .task(id: viewModel.kind) {
                async let reloadTask: Void = viewModel.reload()
                async let continueTask: Void = viewModel.loadContinueWatching()
                _ = await (reloadTask, continueTask)
            }
            .task {
                await viewModel.applyInitialPreferencesIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Media Type", selection: $viewModel.kind) {
                        Text("Movies").tag(MediaKind.movie)
                        Text("TV Shows").tag(MediaKind.tv)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            ErrorView(error: error) { Task { await viewModel.reload() } }
        case .loaded(let shelves):
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    if !viewModel.continueWatchingItems.isEmpty {
                        SectionHeader(title: "Continue Watching")
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 40) {
                                ForEach(viewModel.continueWatchingItems) { item in
                                    Button { onSelect(item) } label: {
                                        MediaCard(
                                            item: item,
                                            playbackProgress: viewModel.progressByID[item.id]
                                        )
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                        }
                    }

                    ForEach(shelves) { shelf in
                        SectionHeader(title: shelf.title)
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 40) {
                                ForEach(shelf.items) { item in
                                    Button { onSelect(item) } label: {
                                        MediaCard(
                                            item: item,
                                            playbackProgress: viewModel.progressByID[item.id]
                                        )
                                    }
                                    .buttonStyle(.card)
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
