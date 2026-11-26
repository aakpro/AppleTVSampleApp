import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DiscoveryView: View {
    @State private var viewModel: DiscoveryViewModel
    private let onSelect: (MediaItem) -> Void
    private let onPlay: ((MediaItem) -> Void)?

    public init(
        viewModel: DiscoveryViewModel,
        onSelect: @escaping (MediaItem) -> Void,
        onPlay: ((MediaItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelect = onSelect
        self.onPlay = onPlay
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            content
        }
        .task(id: viewModel.kind) {
            async let reloadTask: Void = viewModel.reload()
            async let continueTask: Void = viewModel.loadContinueWatching()
            _ = await (reloadTask, continueTask)
        }
        .task {
            await viewModel.applyInitialPreferencesIfNeeded()
        }
    }

    private var header: some View {
        HStack(spacing: 24) {
            Text("Discover")
                .font(SampleTVTheme.Typography.screenTitle)

            Spacer()

            Picker("Media Type", selection: $viewModel.kind) {
                Text("Movies").tag(MediaKind.movie)
                Text("TV Shows").tag(MediaKind.tv)
            }
            .pickerStyle(.segmented)
            .fixedSize()
            .accessibilityIdentifier("discover.kindPicker")
        }
        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
        .padding(.top, 24)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let error):
            ErrorView(error: error) { Task { await viewModel.reload() } }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded:
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    if let featured = viewModel.featuredItem {
                        DiscoveryHeroBanner(
                            item: featured,
                            onPlay: { (onPlay ?? onSelect)(featured) },
                            onDetails: { onSelect(featured) }
                        )
                    }

                    if !viewModel.continueWatchingItems.isEmpty {
                        MediaShelfRow(
                            title: "Continue Watching",
                            items: viewModel.continueWatchingItems,
                            progressByID: viewModel.progressByID,
                            onSelect: onSelect
                        )
                    }

                    ForEach(viewModel.presentedShelves) { shelf in
                        MediaShelfRow(
                            title: shelf.title,
                            items: shelf.items,
                            progressByID: viewModel.progressByID,
                            onSelect: onSelect
                        )
                    }
                }
                .padding(.vertical, 28)
            }
        }
    }
}
