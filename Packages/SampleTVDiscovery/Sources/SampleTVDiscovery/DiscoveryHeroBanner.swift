import SampleTVDomain
import SampleTVUI
import SwiftUI

/// Featured hero banner rendered at the top of Discover.
struct DiscoveryHeroBanner: View {
    let item: MediaItem
    let onPlay: () -> Void
    let onDetails: () -> Void

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backdropLayer
                .frame(maxWidth: .infinity)
                .frame(height: SampleTVTheme.heroHeight)
                .clipShape(RoundedRectangle(cornerRadius: SampleTVTheme.heroCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Text(item.title)
                    .font(SampleTVTheme.Typography.screenTitle)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                metadataRow

                if !item.overview.isEmpty {
                    Text(item.overview)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.85))
                        .lineLimit(3)
                        .frame(maxWidth: 760, alignment: .leading)
                }

                HStack(spacing: 20) {
                    Button {
                        onPlay()
                    } label: {
                        Label("Play", systemImage: "play.fill")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("discover.heroPlayButton")

                    Button {
                        onDetails()
                    } label: {
                        Label("More Info", systemImage: "info.circle")
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("discover.heroDetailsButton")
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 52)
            .padding(.vertical, 42)
        }
        .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)
    }

    private var backdropLayer: some View {
        let backdropURL = ImageURLBuilder().url(
            for: item.backdropPath ?? item.posterPath,
            size: .w1280
        )
        return ZStack {
            PosterImage(url: backdropURL, title: item.title, aspectRatio: nil)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            LinearGradient(
                colors: [
                    SampleTVTheme.Colors.canvas.opacity(0.95),
                    SampleTVTheme.Colors.canvas.opacity(0.65),
                    SampleTVTheme.Colors.canvas.opacity(0.18)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )

            LinearGradient(
                colors: [
                    .clear,
                    SampleTVTheme.Colors.canvas.opacity(0.9)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 14) {
            if let year = item.releaseYear {
                Text(String(year))
            }
            if let rating = item.rating, rating > 0 {
                Text("★ \(rating.formatted(.number.precision(.fractionLength(1))))")
                    .foregroundStyle(.yellow)
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(.white.opacity(0.85))
    }
}
