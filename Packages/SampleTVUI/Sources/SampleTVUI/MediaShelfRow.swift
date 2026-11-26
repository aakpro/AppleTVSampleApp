import SampleTVDomain
import SwiftUI

/// Horizontal media shelf with tvOS-safe content margins and focus clipping disabled.
public struct MediaShelfRow: View {
    private let title: String
    private let items: [MediaItem]
    private let images: ImageURLBuilder
    private let progressByID: [MediaID: Double]
    private let horizontalMargin: CGFloat
    private let onSelect: (MediaItem) -> Void

    public init(
        title: String,
        items: [MediaItem],
        images: ImageURLBuilder = ImageURLBuilder(),
        progressByID: [MediaID: Double] = [:],
        horizontalMargin: CGFloat = SampleTVTheme.horizontalSafeMargin,
        onSelect: @escaping (MediaItem) -> Void
    ) {
        self.title = title
        self.items = items
        self.images = images
        self.progressByID = progressByID
        self.horizontalMargin = horizontalMargin
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(SampleTVTheme.Typography.sectionTitle)
                .foregroundStyle(.primary)
                .padding(.horizontal, horizontalMargin)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: SampleTVTheme.shelfItemSpacing) {
                    ForEach(items) { item in
                        MediaCard(
                            item: item,
                            images: images,
                            playbackProgress: progressByID[item.id]
                        ) {
                            onSelect(item)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, horizontalMargin, for: .scrollContent)
            .contentMargins(.vertical, SampleTVTheme.shelfVerticalMargin, for: .scrollContent)
            .scrollClipDisabled()
        }
    }
}
