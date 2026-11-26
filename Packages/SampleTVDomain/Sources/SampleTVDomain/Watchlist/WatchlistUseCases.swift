import Foundation

// MARK: - Use Cases

public struct GetWatchlist: Sendable {
    private let store: any WatchlistStore

    public init(store: any WatchlistStore) {
        self.store = store
    }

    public func callAsFunction(for profileID: String) async throws -> [MediaItem] {
        try await store.items(for: profileID)
    }
}

public struct ToggleWatchlist: Sendable {
    private let store: any WatchlistStore

    public init(store: any WatchlistStore) {
        self.store = store
    }

    public func callAsFunction(_ item: MediaItem, for profileID: String) async throws -> Bool {
        try await store.toggle(item, for: profileID)
    }
}

public struct IsInWatchlist: Sendable {
    private let store: any WatchlistStore

    public init(store: any WatchlistStore) {
        self.store = store
    }

    public func callAsFunction(_ mediaID: MediaID, for profileID: String) async throws -> Bool {
        try await store.contains(mediaID, in: profileID)
    }
}
