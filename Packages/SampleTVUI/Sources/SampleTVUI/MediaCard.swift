import SampleTVDomain
import SwiftUI

public struct PosterImage: View {
    private let url: URL?

    public init(url: URL?) {
        self.url = url
    }

    public var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(2 / 3, contentMode: .fit)
            default:
                Rectangle()
                    .fill(.quaternary)
                    .aspectRatio(2 / 3, contentMode: .fit)
                    .overlay { Image(systemName: "film").font(.largeTitle) }
            }
        }
    }
}

/// Focusable poster card. Wrap in a `Button` with `.buttonStyle(.card)` at the call site.
public struct MediaCard: View {
    private let item: MediaItem
    private let images: ImageURLBuilder

    public init(item: MediaItem, images: ImageURLBuilder = ImageURLBuilder()) {
        self.item = item
        self.images = images
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PosterImage(url: images.url(for: item.posterPath, size: .w342))
            Text(item.title).font(.callout).lineLimit(1)
            if let year = item.releaseYear {
                Text(String(year)).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}