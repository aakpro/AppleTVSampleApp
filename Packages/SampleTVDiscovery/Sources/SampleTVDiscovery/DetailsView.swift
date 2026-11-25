import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DetailsView: View {
    @State private var viewModel: DetailsViewModel
    private let onPlay: (MediaItem) -> Void
    private let onPlayTrailer: ((MediaItem) -> Void)?
    private let onSelectRecommendation: ((MediaItem) -> Void)?

    public init(
        viewModel: DetailsViewModel,
        onPlay: @escaping (MediaItem) -> Void,
        onPlayTrailer: ((MediaItem) -> Void)? = nil,
        onSelectRecommendation: ((MediaItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onPlay = onPlay
        self.onPlayTrailer = onPlayTrailer
        self.onSelectRecommendation = onSelectRecommendation
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                HStack(alignment: .top, spacing: 60) {
                    PosterImage(url: ImageURLBuilder().url(for: viewModel.item.posterPath, size: .w500))
                        .frame(width: 400)

                    VStack(alignment: .leading, spacing: 24) {
                        Text(viewModel.item.title).font(.largeTitle)
                        Text(viewModel.item.overview)

                        if case .loaded(let details) = viewModel.state {
                            Text(details.genres.map(\.name).joined(separator: " · "))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 24) {
                                Button(viewModel.resumeLabel) {
                                    onPlay(viewModel.item)
                                }
                                .buttonStyle(.card)

                                if viewModel.trailerResource != nil || !details.videos.isEmpty {
                                    Button("Watch Trailer") {
                                        onPlayTrailer?(viewModel.item)
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                        }

                        Spacer(minLength: 24)

                        Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

                if case .loaded(let details) = viewModel.state, !details.recommendations.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("More Like This")
                            .font(.title2)
                            .fontWeight(.semibold)

                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 40) {
                                ForEach(details.recommendations) { recommendation in
                                    Button {
                                        onSelectRecommendation?(recommendation)
                                    } label: {
                                        MediaCard(item: recommendation)
                                    }
                                    .buttonStyle(.card)
                                }
                            }
                        }
                    }
                }
            }
            .padding(60)
        }
        .task { await viewModel.load() }
    }
}
