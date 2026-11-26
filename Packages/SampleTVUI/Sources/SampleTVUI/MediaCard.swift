import SampleTVDomain
import SwiftUI

/// Poster card with a focusable artwork button and fixed-height metadata footer below.
public struct MediaCard: View {
    private let item: MediaItem
    private let images: ImageURLBuilder
    private let playbackProgress: Double?
    private let onSelect: (() -> Void)?

    public init(
        item: MediaItem,
        images: ImageURLBuilder = ImageURLBuilder(),
        playbackProgress: Double? = nil,
        onSelect: (() -> Void)? = nil
    ) {
        self.item = item
        self.images = images
        self.playbackProgress = playbackProgress
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let onSelect {
                Button(action: onSelect) {
                    posterContent
                }
                .buttonStyle(.card)
                .accessibilityLabel(accessibilitySummary)
            } else {
                posterContent
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilitySummary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(SampleTVTheme.Typography.cardTitle)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                metadataRow
            }
            .accessibilityHidden(onSelect != nil)
        }
        .frame(width: SampleTVTheme.cardWidth, alignment: .leading)
    }

    private var posterContent: some View {
        PosterImage(
            url: images.url(for: item.posterPath, size: .w342),
            title: item.title
        )
        .frame(width: SampleTVTheme.cardWidth)
        .overlay(alignment: .bottom) {
            if let progress = playbackProgress {
                progressOverlay(progress: min(max(progress, 0), 1))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: SampleTVTheme.cardCornerRadius, style: .continuous))
    }

    private func progressOverlay(progress: Double) -> some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.clear, .black.opacity(0.65)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 28)
            .overlay(alignment: .bottom) {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.28))
                        Capsule()
                            .fill(Color.accentColor)
                            .frame(width: max(8, proxy.size.width * progress))
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
        }
    }

    private var metadataRow: some View {
        HStack(spacing: 8) {
            if let year = item.releaseYear {
                Text(String(year))
            }
            if let rating = item.rating, rating > 0 {
                Text("★ \(rating.formatted(.number.precision(.fractionLength(1))))")
            }
        }
        .font(SampleTVTheme.Typography.cardMetadata)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .frame(height: 20, alignment: .leading)
    }

    private var accessibilitySummary: String {
        var parts = [item.title]
        if let year = item.releaseYear {
            parts.append(String(year))
        }
        if let rating = item.rating, rating > 0 {
            parts.append("rated \(rating.formatted(.number.precision(.fractionLength(1))))")
        }
        return parts.joined(separator: ", ")
    }
}
