import SwiftUI

/// Uniform focusable tvOS category tile using `Button` with `.buttonStyle(.card)`.
public struct CategoryTile: View {
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage ?? Self.defaultSymbol(for: title)
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.tint)

                Text(title)
                    .font(SampleTVTheme.Typography.tileTitle)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(width: SampleTVTheme.tileWidth, height: SampleTVTheme.tileHeight)
            .padding(20)
            .background(
                LinearGradient(
                    colors: [
                        SampleTVTheme.Colors.surface,
                        SampleTVTheme.Colors.elevatedSurface
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: SampleTVTheme.tileCornerRadius, style: .continuous))
        }
        .buttonStyle(.card)
        .accessibilityLabel(title)
    }

    private static let symbolByTitle: [String: String] = [
        "all movies": "film.stack",
        "all tv shows": "tv",
        "action": "flame.fill",
        "action & adventure": "flame.fill",
        "adventure": "safari.fill",
        "animation": "sparkles",
        "comedy": "face.smiling",
        "crime": "shield.lefthalf.filled",
        "documentary": "doc.text.image",
        "drama": "theatermasks.fill",
        "family": "figure.2.and.child.holdinghands",
        "kids": "figure.2.and.child.holdinghands",
        "fantasy": "wand.and.stars",
        "history": "clock.arrow.circlepath",
        "horror": "moon.stars.fill",
        "music": "music.note",
        "mystery": "magnifyingglass",
        "romance": "heart.fill",
        "science fiction": "atom",
        "sci-fi & fantasy": "atom",
        "thriller": "bolt.fill",
        "war": "shield.fill",
        "war & politics": "shield.fill",
        "western": "sun.dust.fill"
    ]

    public static func defaultSymbol(for title: String) -> String {
        symbolByTitle[title.lowercased()] ?? "film.fill"
    }
}
