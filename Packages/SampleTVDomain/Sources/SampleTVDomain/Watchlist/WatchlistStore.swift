import Foundation

// MARK: - Watchlist Store Protocol

public protocol WatchlistStore: Sendable {
    func items(for profileID: String) async throws -> [MediaItem]
    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool
    func add(_ item: MediaItem, to profileID: String) async throws
    func remove(_ mediaID: MediaID, from profileID: String) async throws
    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool
}
