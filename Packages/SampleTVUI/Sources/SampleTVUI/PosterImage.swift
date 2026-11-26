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
