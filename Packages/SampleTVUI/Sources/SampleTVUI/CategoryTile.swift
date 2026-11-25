import SwiftUI

/// Focusable tvOS category tile using `Button` with `.buttonStyle(.card)`.
public struct CategoryTile: View {
    private let title: String
    private let action: () -> Void

    public init(title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: "film.stack")
                    .font(.title2)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 140)
            .padding(20)
        }
        .buttonStyle(.card)
    }
}
