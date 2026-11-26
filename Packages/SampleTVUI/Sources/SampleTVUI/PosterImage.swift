import SwiftUI

public struct PosterImage: View {
    private enum LoadState {
        case loading
        case loaded(Image)
        case failed
    }

    private let url: URL?
    private let title: String?
    private let aspectRatio: CGFloat?
    @State private var loadState: LoadState

    public init(
        url: URL?,
        title: String? = nil,
        aspectRatio: CGFloat? = SampleTVTheme.posterAspectRatio
    ) {
        self.url = url
        self.title = title
        self.aspectRatio = aspectRatio
        self._loadState = State(initialValue: url == nil ? .failed : .loading)
    }

    public var body: some View {
        container
            .overlay {
                content
            }
            .clipped()
            .task(id: url) {
                await fetch()
            }
    }

    @ViewBuilder
    private var container: some View {
        if let aspectRatio {
            Color.clear.aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            Color.clear
        }
    }

    @ViewBuilder
    private var content: some View {
        switch loadState {
        case .loading:
            loadingView
        case .loaded(let image):
            image
                .resizable()
                .scaledToFill()
        case .failed:
            fallbackView
        }
    }

    private var loadingView: some View {
        Rectangle()
            .fill(SampleTVTheme.Colors.surface)
            .overlay {
                ProgressView()
                    .controlSize(.small)
            }
    }

    private var fallbackView: some View {
        LinearGradient(
            colors: [
                SampleTVTheme.Colors.fallbackTop,
                SampleTVTheme.Colors.fallbackBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            VStack(spacing: 8) {
                Image(systemName: "film")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(12)
        }
    }

    private func fetch() async {
        guard let url else {
            loadState = .failed
            return
        }

        if case .loaded = loadState {
            // Keep existing image on redraws if URL did not change.
        } else {
            loadState = .loading
        }

        do {
            let image = try await CachedImageLoader.shared.loadImage(from: url)
            if !Task.isCancelled {
                loadState = .loaded(image)
            }
        } catch is CancellationError {
            return
        } catch {
            if !Task.isCancelled {
                loadState = .failed
            }
        }
    }
}

#Preview {
    PosterImage(
        url: URL(string: "https://image.tmdb.org/t/p/w342/or06FN3Dka5tukK1e9sl16pB3iy.jpg"),
        title: "Avengers: Endgame"
    )
    .frame(width: SampleTVTheme.cardWidth)
}
