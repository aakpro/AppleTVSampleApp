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
                LazyVStack(alignment: .leading, spacing: 28) {
                    if !viewModel.continueWatchingItems.isEmpty {
                        MediaShelfRow(
                            title: "Continue Watching",
                            items: viewModel.continueWatchingItems,
                            progressByID: viewModel.progressByID,
                            onSelect: onSelect
                        )
                    }

                    ForEach(shelves) { shelf in
                        MediaShelfRow(
                            title: shelf.title,
                            items: shelf.items,
                            progressByID: viewModel.progressByID,
                            onSelect: onSelect
                        )
                    }
                }
                .padding(.vertical, 48)
            }
        }
    }
}
