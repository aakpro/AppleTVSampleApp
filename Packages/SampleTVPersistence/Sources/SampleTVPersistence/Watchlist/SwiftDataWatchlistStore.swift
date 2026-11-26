import Foundation
import SampleTVDomain
import SwiftData

/// SwiftData-backed watchlist store scoped per viewer profile.
@ModelActor
public actor SwiftDataWatchlistStore: WatchlistStore {
    public init(inMemory: Bool = false) throws {
        let container = try PersistenceContainer.makeModelContainer(inMemory: inMemory)
        self.init(modelContainer: container)
    }

    public func items(for profileID: String) async throws -> [MediaItem] {
        let targetProfileID = profileID
        let descriptor = FetchDescriptor<StoredWatchlistItem>(
            predicate: #Predicate { $0.profileID == targetProfileID },
            sortBy: [SortDescriptor(\StoredWatchlistItem.addedAt, order: .reverse)]
        )
        let storedItems = try modelContext.fetch(descriptor)
        return storedItems.map(\.mediaItem)
    }

    public func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool {
        try containsSync(mediaID, in: profileID)
    }

    public func add(_ item: MediaItem, to profileID: String) async throws {
        try addSync(item, to: profileID)
    }

    public func remove(_ mediaID: MediaID, from profileID: String) async throws {
        try removeSync(mediaID, from: profileID)
    }

    public func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool {
        if try containsSync(item.id, in: profileID) {
            try removeSync(item.id, from: profileID)
            return false
        }
        try addSync(item, to: profileID)
        return true
    }

    private func itemDescriptor(
        for mediaID: MediaID,
        in profileID: String
    ) -> FetchDescriptor<StoredWatchlistItem> {
        let targetProfileID = profileID
        let kindRaw = mediaID.kind.rawValue
        let value = mediaID.value
        return FetchDescriptor<StoredWatchlistItem>(
            predicate: #Predicate {
                $0.profileID == targetProfileID &&
                    $0.mediaKindRaw == kindRaw &&
                    $0.mediaIDValue == value
            }
        )
    }

    private func containsSync(_ mediaID: MediaID, in profileID: String) throws -> Bool {
        let descriptor = itemDescriptor(for: mediaID, in: profileID)
        return try modelContext.fetchCount(descriptor) > 0
    }

    private func addSync(_ item: MediaItem, to profileID: String) throws {
        guard try !containsSync(item.id, in: profileID) else { return }
        let storedItem = StoredWatchlistItem(profileID: profileID, mediaItem: item)
        modelContext.insert(storedItem)
        try modelContext.save()
    }

    private func removeSync(_ mediaID: MediaID, from profileID: String) throws {
        let descriptor = itemDescriptor(for: mediaID, in: profileID)
        let storedItems = try modelContext.fetch(descriptor)
        guard !storedItems.isEmpty else { return }
        for item in storedItems {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}
