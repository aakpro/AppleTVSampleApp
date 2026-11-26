import Foundation

public struct MediaShelf: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let items: [MediaItem]

    public init(id: String = UUID().uuidString, title: String, items: [MediaItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}
