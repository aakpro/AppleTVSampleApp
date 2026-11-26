import Foundation
import SampleTVDomain
import SwiftData

/// SwiftData-backed playback progress store scoped per viewer profile.
@ModelActor
public actor SwiftDataPlaybackProgressStore: PlaybackProgressStore {
    public init(inMemory: Bool = false) throws {
        let container = try PersistenceContainer.makeModelContainer(inMemory: inMemory)
        self.init(modelContainer: container)
    }

    public func loadProgress(for mediaID: MediaID, profileID: String) async throws -> PlaybackProgress? {
        let descriptor = progressDescriptor(for: mediaID, profileID: profileID)
        return try modelContext.fetch(descriptor).first?.playbackProgress
    }

    public func saveProgress(_ progress: PlaybackProgress) async throws {
        let descriptor = progressDescriptor(for: progress.mediaID, profileID: progress.profileID)
        if let existing = try modelContext.fetch(descriptor).first {
            existing.position = progress.position
            existing.duration = progress.duration
            existing.updatedAt = progress.updatedAt
            existing.seasonNumber = progress.seasonNumber
            existing.episodeNumber = progress.episodeNumber
        } else {
            modelContext.insert(StoredProgress(progress: progress))
        }
        try modelContext.save()
    }

    public func clearProgress(for mediaID: MediaID, profileID: String) async throws {
        let descriptor = progressDescriptor(for: mediaID, profileID: profileID)
        let matches = try modelContext.fetch(descriptor)
        guard !matches.isEmpty else { return }
        for entry in matches {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    public func clearAllProgress(for profileID: String) async throws {
        let targetProfileID = profileID
        let descriptor = FetchDescriptor<StoredProgress>(
            predicate: #Predicate { $0.profileID == targetProfileID }
        )
        let matches = try modelContext.fetch(descriptor)
        guard !matches.isEmpty else { return }
        for entry in matches {
            modelContext.delete(entry)
        }
        try modelContext.save()
    }

    public func recentlyWatched(for profileID: String, maxCount: Int) async throws -> [PlaybackProgress] {
        guard maxCount > 0 else { return [] }
        let targetProfileID = profileID
        var descriptor = FetchDescriptor<StoredProgress>(
            predicate: #Predicate { $0.profileID == targetProfileID },
            sortBy: [SortDescriptor(\StoredProgress.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = maxCount
        return try modelContext.fetch(descriptor).map(\.playbackProgress)
    }

    private func progressDescriptor(
        for mediaID: MediaID,
        profileID: String
    ) -> FetchDescriptor<StoredProgress> {
        let targetProfileID = profileID
        let kindRaw = mediaID.kind.rawValue
        let value = mediaID.value
        return FetchDescriptor<StoredProgress>(
            predicate: #Predicate {
                $0.profileID == targetProfileID &&
                    $0.mediaKindRaw == kindRaw &&
                    $0.mediaIDValue == value
            }
        )
    }
}
