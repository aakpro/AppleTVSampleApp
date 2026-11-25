import SampleTVDomain

@MainActor
extension DiscoveryViewModel {
    /// Loads recently watched, unfinished items from `progressStore` and resolves their metadata.
    public func loadContinueWatching() async {
        guard let progressStore else {
            continueWatchingItems = []
            progressByID = [:]
            return
        }

        do {
            let records = try await progressStore.recentlyWatched(maxCount: 10)
                .filter { !$0.isWatched && $0.position > 0 }
            guard !records.isEmpty else {
                continueWatchingItems = []
                progressByID = [:]
                return
            }

            var fractions: [MediaID: Double] = [:]
            for record in records where record.duration > 0 {
                fractions[record.mediaID] = record.position / record.duration
            }
            progressByID = fractions

            let loadedByID = Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var resolvedByID: [MediaID: MediaItem] = [:]

            for record in records where loadedByID[record.mediaID] != nil {
                resolvedByID[record.mediaID] = loadedByID[record.mediaID]
            }

            let missingIDs = records.map(\.mediaID).filter { resolvedByID[$0] == nil }
            if !missingIDs.isEmpty, let getDetails {
                await withTaskGroup(of: (MediaID, MediaItem?).self) { group in
                    for id in missingIDs {
                        group.addTask {
                            let details = try? await getDetails(id)
                            return (id, details?.item)
                        }
                    }
                    for await (id, item) in group {
                        if let item {
                            resolvedByID[id] = item
                        }
                    }
                }
            }

            continueWatchingItems = records.compactMap { resolvedByID[$0.mediaID] }
        } catch is CancellationError {
            return
        } catch {
            continueWatchingItems = []
            progressByID = [:]
        }
    }
}
