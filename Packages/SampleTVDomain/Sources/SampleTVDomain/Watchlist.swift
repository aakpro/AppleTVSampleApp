import Foundation

// MARK: - Watchlist Store Protocol

public protocol WatchlistStore: Sendable {
    func items(for profileID: String) async throws -> [MediaItem]
    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool
    func add(_ item: MediaItem, to profileID: String) async throws
    func remove(_ mediaID: MediaID, from profileID: String) async throws
    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool
}

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
