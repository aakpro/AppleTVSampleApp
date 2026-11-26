import SampleTVDomain
import SampleTVUI
import SwiftUI

/// Focusable tvOS 16:9 episode card with unclipped metadata below the platter.
struct EpisodeCard: View {
    let episode: TVEpisode
    let fallbackImagePath: String?
    let isSelected: Bool
    let onPlay: () -> Void

    private let images = ImageURLBuilder()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onPlay) {
                thumbnailContent
            }
            .buttonStyle(.card)
            .accessibilityLabel(accessibilitySummary)
            .accessibilityIdentifier("details.episodeCard.\(episode.seasonNumber).\(episode.episodeNumber)")

            VStack(alignment: .leading, spacing: 4) {
                Text("\(episode.episodeNumber). \(episode.name)")
                    .font(SampleTVTheme.Typography.cardTitle)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                metadataRow

                Text(episode.overview)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
                    .frame(height: 36, alignment: .topLeading)
            }
            .accessibilityHidden(true)
        }
        .frame(width: SampleTVTheme.episodeCardWidth, alignment: .leading)
    }

    private var thumbnailContent: some View {
        let imageURL = images.url(for: episode.stillPath ?? fallbackImagePath, size: .w500)
        return PosterImage(
            url: imageURL,
            title: episode.name,
            aspectRatio: SampleTVTheme.episodeAspectRatio
        )
        .frame(width: SampleTVTheme.episodeCardWidth)
        .overlay(alignment: .topLeading) {
            HStack {
                Text(episode.episodeCode)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.72), in: Capsule())

                Spacer()

                if isSelected {
                    Label("Selected", systemImage: "checkmark.circle.fill")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.accentColor.opacity(0.9), in: Capsule())
                }
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: SampleTVTheme.cardCornerRadius, style: .continuous))
    }

    private var metadataRow: some View {
        HStack(spacing: 10) {
            if let minutes = episode.runtimeMinutes, minutes > 0 {
                Text("\(minutes)m")
            }
            if let rating = episode.rating, rating > 0 {
                Text("★ \(rating.formatted(.number.precision(.fractionLength(1))))")
                    .foregroundStyle(.yellow)
            }
            if let airDate = episode.airDate, !airDate.isEmpty {
                Text(airDate)
            }
        }
        .font(SampleTVTheme.Typography.cardMetadata)
        .foregroundStyle(.white.opacity(0.75))
        .lineLimit(1)
        .frame(height: 20, alignment: .leading)
    }

    private var accessibilitySummary: String {
        var parts = [episode.episodeCode, episode.name]
        if let minutes = episode.runtimeMinutes, minutes > 0 {
            parts.append("\(minutes) minutes")
        }
        if let rating = episode.rating, rating > 0 {
            parts.append("rated \(rating.formatted(.number.precision(.fractionLength(1))))")
        }
        if isSelected {
            parts.append("selected")
        }
        return parts.joined(separator: ", ")
    }
}
