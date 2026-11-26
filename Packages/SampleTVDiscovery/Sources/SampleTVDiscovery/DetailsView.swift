import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct DetailsView: View {
    @State private var viewModel: DetailsViewModel
    private let isPreviewPaused: Bool
    private let onPlay: (MediaItem) -> Void
    private let onPlayTrailer: ((MediaItem) -> Void)?
    private let onSelectRecommendation: ((MediaItem) -> Void)?

    public init(
        viewModel: DetailsViewModel,
        isPreviewPaused: Bool = false,
        onPlay: @escaping (MediaItem) -> Void,
        onPlayTrailer: ((MediaItem) -> Void)? = nil,
        onSelectRecommendation: ((MediaItem) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.isPreviewPaused = isPreviewPaused
        self.onPlay = onPlay
        self.onPlayTrailer = onPlayTrailer
        self.onSelectRecommendation = onSelectRecommendation
    }

    public var body: some View {
        ZStack {
            backdropCanvas

            ScrollView {
                VStack(alignment: .leading, spacing: 44) {
                    heroDetailsSection
                        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)

                    if case .loaded(let details) = viewModel.state, !details.recommendations.isEmpty {
                        MediaShelfRow(
                            title: "More Like This",
                            items: details.recommendations
                        ) { recommendation in
                            onSelectRecommendation?(recommendation)
                        }
                    }

                    Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
                }
                .padding(.vertical, 60)
            }
        }
        .task { await viewModel.load() }
    }

    private var backdropCanvas: some View {
        let backdropURL = ImageURLBuilder().url(
            for: viewModel.item.backdropPath ?? viewModel.item.posterPath,
            size: .w1280
        )
        return ZStack {
            SampleTVTheme.Colors.canvas
                .ignoresSafeArea()

            PosterImage(url: backdropURL, title: viewModel.item.title, aspectRatio: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()

            if viewModel.shouldAutoplayTrailer, let trailerURL = viewModel.trailerResource?.url {
                MutedTrailerBackdropView(url: trailerURL, isPaused: isPreviewPaused)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            LinearGradient(
                colors: [
                    SampleTVTheme.Colors.canvas.opacity(0.95),
                    SampleTVTheme.Colors.canvas.opacity(0.78),
                    SampleTVTheme.Colors.canvas.opacity(0.65)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    SampleTVTheme.Colors.canvas.opacity(0.35),
                    SampleTVTheme.Colors.canvas.opacity(0.96)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var heroDetailsSection: some View {
        HStack(alignment: .top, spacing: 56) {
            PosterImage(
                url: ImageURLBuilder().url(for: viewModel.item.posterPath, size: .w500),
                title: viewModel.item.title
            )
            .frame(width: 360)
            .clipShape(RoundedRectangle(cornerRadius: SampleTVTheme.cardCornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.5), radius: 24, y: 12)

            VStack(alignment: .leading, spacing: 22) {
                Text(viewModel.item.title)
                    .font(SampleTVTheme.Typography.screenTitle)
                    .foregroundStyle(.white)

                metadataSummaryRow

                if !viewModel.item.overview.isEmpty {
                    Text(viewModel.item.overview)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.88))
                        .frame(maxWidth: 820, alignment: .leading)
                }

                if case .loaded(let details) = viewModel.state {
                    if !details.genres.isEmpty {
                        genrePills(details.genres)
                    }

                    actionButtons(details: details)
                        .padding(.top, 8)
                }
            }
        }
    }

    private var metadataSummaryRow: some View {
        HStack(spacing: 16) {
            if let year = viewModel.item.releaseYear {
                Text(String(year))
            }
            if let rating = viewModel.item.rating, rating > 0 {
                Text("★ \(rating.formatted(.number.precision(.fractionLength(1))))")
                    .foregroundStyle(.yellow)
            }
            if case .loaded(let details) = viewModel.state {
                if let formattedDuration = formattedDurationText(details: details) {
                    Text(formattedDuration)
                }
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white.opacity(0.8))
    }

    private func formattedDurationText(details: MediaDetails) -> String? {
        if let minutes = details.runtimeMinutes, minutes > 0 {
            let hours = minutes / 60
            let mins = minutes % 60
            return hours > 0 ? String(format: "%dh %02dm", hours, mins) : "\(mins)m"
        }
        if let seasons = details.seasonCount, seasons > 0 {
            return seasons == 1 ? "1 Season" : "\(seasons) Seasons"
        }
        return nil
    }

    private func genrePills(_ genres: [Genre]) -> some View {
        HStack(spacing: 10) {
            ForEach(genres.prefix(5)) { genre in
                Text(genre.name)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.14), in: Capsule())
            }
        }
    }

    private func actionButtons(details: MediaDetails) -> some View {
        HStack(spacing: 24) {
            Button {
                onPlay(viewModel.item)
            } label: {
                Label(viewModel.resumeLabel, systemImage: "play.fill")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("details.playButton")

            if viewModel.trailerResource != nil || !details.videos.isEmpty {
                Button {
                    onPlayTrailer?(viewModel.item)
                } label: {
                    Label("Watch Trailer", systemImage: "film")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("details.trailerButton")
            }

            Button {
                Task {
                    await viewModel.toggleWatchlist()
                }
            } label: {
                Label(
                    viewModel.isInWatchlist ? "In My List" : "Add to My List",
                    systemImage: viewModel.isInWatchlist ? "checkmark" : "plus"
                )
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("details.watchlistButton")
        }
    }
}
