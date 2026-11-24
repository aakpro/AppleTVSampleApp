import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DetailsView: View {
    @State private var viewModel: DetailsViewModel
    private let onPlay: (MediaItem) -> Void

    public init(viewModel: DetailsViewModel, onPlay: @escaping (MediaItem) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onPlay = onPlay
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 60) {
            PosterImage(url: ImageURLBuilder().url(for: viewModel.item.posterPath, size: .w500))
                .frame(width: 400)
            VStack(alignment: .leading, spacing: 24) {
                Text(viewModel.item.title).font(.largeTitle)
                Text(viewModel.item.overview)
                if case .loaded(let details) = viewModel.state {
                    Text(details.genres.map(\.name).joined(separator: " · ")).foregroundStyle(.secondary)
                }
                Button("Play") { onPlay(viewModel.item) }
            }
        }
        .padding(60)
        .task { await viewModel.load() }
    }
}