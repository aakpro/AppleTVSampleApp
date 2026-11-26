import SwiftUI

/// Design tokens shared across SampleTV's tvOS interface.
public enum SampleTVTheme: Sendable {
    /// Primary 2:3 poster aspect ratio.
    public static let posterAspectRatio: CGFloat = 2.0 / 3.0

    /// Standard card and surface corner radii.
    public static let cardCornerRadius: CGFloat = 12
    public static let tileCornerRadius: CGFloat = 16
    public static let heroCornerRadius: CGFloat = 20

    /// Layout spacing and tvOS safe margins (40pt+ focus growth buffer).
    public static let horizontalSafeMargin: CGFloat = 60
    public static let shelfVerticalMargin: CGFloat = 24
    public static let shelfItemSpacing: CGFloat = 28
    public static let sectionSpacing: CGFloat = 44

    /// Component sizing defaults.
    public static let cardWidth: CGFloat = 220
    public static let tileWidth: CGFloat = 280
    public static let tileHeight: CGFloat = 150
    public static let heroHeight: CGFloat = 440

    /// Cinema-dark surface palette tailored for tvOS 10-foot viewing.
    public enum Colors: Sendable {
        public static let canvas = Color(red: 0.055, green: 0.063, blue: 0.082)
        public static let surface = Color(red: 0.106, green: 0.122, blue: 0.161)
        public static let elevatedSurface = Color(red: 0.153, green: 0.173, blue: 0.224)
        public static let fallbackTop = Color(red: 0.137, green: 0.157, blue: 0.208)
        public static let fallbackBottom = Color(red: 0.075, green: 0.086, blue: 0.118)
        public static let focusScrim = Color.black.opacity(0.65)
        public static let glassBorder = Color.white.opacity(0.14)
    }

    /// Typography helpers consistent with tvOS 17+.
    public enum Typography: Sendable {
        public static let screenTitle: Font = .largeTitle.bold()
        public static let sectionTitle: Font = .title3.weight(.semibold)
        public static let cardTitle: Font = .callout.weight(.semibold)
        public static let cardMetadata: Font = .caption
        public static let tileTitle: Font = .headline.weight(.semibold)
    }
}
