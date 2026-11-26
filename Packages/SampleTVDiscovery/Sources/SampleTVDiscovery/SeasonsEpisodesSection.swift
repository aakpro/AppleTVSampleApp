import SampleTVDomain
import SampleTVUI
import SwiftUI

/// Horizontal season switcher and episode strip rendered for TV shows on the details screen.
struct SeasonsEpisodesSection: View {
    let viewModel: DetailsViewModel
    let onPlayEpisode: (TVEpisode) -> Void

    var body: some View {
        if viewModel.item.id.kind == .tv, !viewModel.availableSeasons.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                headerRow
                seasonSelectorRow
                episodesContent
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Seasons & Episodes")
                .font(SampleTVTheme.Typography.sectionTitle)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            if let seasonDetails = viewModel.selectedSeasonState.loadedSeason {
                let count = seasonDetails.episodes.count
                let episodeLabel = count == 1 ? "1 Episode" : "\(count) Episodes"
                Text("\(seasonDetails.name) · \(episodeLabel)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
    }

    private var seasonSelectorRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(viewModel.availableSeasons, id: \.seasonNumber) { season in
                    seasonButton(for: season)
                }
            }
        }
        .contentMargins(.horizontal, SampleTVTheme.horizontalSafeMargin)
        .contentMargins(.vertical, 12)
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func seasonButton(for season: TVSeason) -> some View {
        let isSelected = viewModel.selectedSeasonNumber == season.seasonNumber
        if isSelected {
            Button {
                Task { await viewModel.selectSeason(season.seasonNumber) }
            } label: {
                seasonLabel(season, isSelected: true)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .accessibilityIdentifier("details.seasonButton.\(season.seasonNumber)")
        } else {
            Button {
                Task { await viewModel.selectSeason(season.seasonNumber) }
            } label: {
                seasonLabel(season, isSelected: false)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("details.seasonButton.\(season.seasonNumber)")
        }
    }

    private func seasonLabel(_ season: TVSeason, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            Text(season.name)
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption.weight(.bold))
            }
        }
        .font(.subheadline.weight(.semibold))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var episodesContent: some View {
        switch viewModel.selectedSeasonState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, minHeight: 240)
        case .failed(let error):
            ErrorView(error: error) {
                Task { await viewModel.retrySelectedSeason() }
            }
            .frame(maxWidth: .infinity, minHeight: 240)
        case .loaded(let seasonDetails):
            if seasonDetails.episodes.isEmpty {
                Text("No episodes available yet.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
                    .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: SampleTVTheme.shelfItemSpacing) {
                        ForEach(seasonDetails.episodes) { episode in
                            EpisodeCard(
                                episode: episode,
                                fallbackImagePath: viewModel.item.backdropPath ?? viewModel.item.posterPath,
                                isSelected: viewModel.selectedEpisode?.id == episode.id
                            ) {
                                viewModel.selectEpisode(episode)
                                onPlayEpisode(episode)
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, SampleTVTheme.horizontalSafeMargin)
                .contentMargins(.vertical, 24)
                .scrollClipDisabled()
            }
        }
    }
}
