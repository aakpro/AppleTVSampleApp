import Foundation

public struct ContinueWatchingItem: Identifiable, Hashable, Sendable {
    public let item: MediaItem
    public let progress: PlaybackProgress

    public var id: MediaID { item.id }

    public var fraction: Double {
        progress.duration > 0 ? min(max(progress.position / progress.duration, 0), 1) : 0
    }

    public init(item: MediaItem, progress: PlaybackProgress) {
        self.item = item
        self.progress = progress
    }
}

public struct GetWatchHistory: Sendable {
    private let store: any PlaybackProgressStore

    public init(store: any PlaybackProgressStore) {
        self.store = store
    }

    public func callAsFunction(
        for profileID: String = ViewerProfile.defaultID,
        maxCount: Int = 100
    ) async throws -> [PlaybackProgress] {
        try await store.recentlyWatched(for: profileID, maxCount: maxCount)
    }
}

public struct LoadPlaybackProgress: Sendable {
    private let store: any PlaybackProgressStore

    public init(store: any PlaybackProgressStore) {
        self.store = store
    }

    public func callAsFunction(
        for mediaID: MediaID,
        profileID: String = ViewerProfile.defaultID
    ) async throws -> PlaybackProgress? {
        try await store.loadProgress(for: mediaID, profileID: profileID)
    }
}

public struct SavePlaybackProgress: Sendable {
    private let store: any PlaybackProgressStore

    public static let minimumSavedPosition: TimeInterval = 5

    public init(store: any PlaybackProgressStore) {
        self.store = store
    }

    public func callAsFunction(_ progress: PlaybackProgress) async throws {
        guard progress.duration > 0,
              progress.position >= Self.minimumSavedPosition || progress.isWatched else {
            return
        }
        try await store.saveProgress(progress)
    }
}

public struct ClearWatchHistory: Sendable {
    private let store: any PlaybackProgressStore

    public init(store: any PlaybackProgressStore) {
        self.store = store
    }

    public func callAsFunction(for profileID: String = ViewerProfile.defaultID) async throws {
        try await store.clearAllProgress(for: profileID)
    }
}

public struct GetContinueWatching: Sendable {
    private let progressStore: any PlaybackProgressStore
    private let mediaRepository: any MediaRepository

    public init(progressStore: any PlaybackProgressStore, mediaRepository: any MediaRepository) {
        self.progressStore = progressStore
        self.mediaRepository = mediaRepository
    }

    public func callAsFunction(
        for profileID: String = ViewerProfile.defaultID,
        kind: MediaKind? = nil,
        maxCount: Int = 10,
        knownItems: [MediaID: MediaItem] = [:]
    ) async throws -> [ContinueWatchingItem] {
        let records = try await progressStore.recentlyWatched(for: profileID, maxCount: maxCount)
            .filter { !$0.isWatched && $0.position > 0 }
            .filter { kind == nil || $0.mediaID.kind == kind }
        guard !records.isEmpty else { return [] }

        var resolvedByID = knownItems
        let missingIDs = records.map(\.mediaID).filter { resolvedByID[$0] == nil }
        if !missingIDs.isEmpty {
            let fetched = await fetchMissingItems(for: missingIDs)
            for (id, item) in fetched {
                resolvedByID[id] = item
            }
        }

        return records.compactMap { record in
            guard let item = resolvedByID[record.mediaID] else { return nil }
            return ContinueWatchingItem(item: item, progress: record)
        }
    }

    private func fetchMissingItems(for ids: [MediaID]) async -> [MediaID: MediaItem] {
        await withTaskGroup(of: (MediaID, MediaItem?).self) { group in
            for id in ids {
                group.addTask {
                    let details = try? await mediaRepository.details(of: id)
                    return (id, details?.item)
                }
            }

            var resolved: [MediaID: MediaItem] = [:]
            for await (id, item) in group {
                if let item {
                    resolved[id] = item
                }
            }
            return resolved
        }
    }
}
