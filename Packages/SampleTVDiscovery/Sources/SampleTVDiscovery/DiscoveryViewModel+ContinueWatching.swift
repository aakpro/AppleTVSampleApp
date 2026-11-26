import SampleTVDomain

@MainActor
extension DiscoveryViewModel {
    /// Loads recently watched, unfinished items from `getContinueWatching`.
    public func loadContinueWatching() async {
        guard let getContinueWatching else {
            continueWatchingItems = []
            progressByID = [:]
            return
        }

        do {
            let knownByID = Dictionary(
                items.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let records = try await getContinueWatching(
                for: profileID,
                kind: kind,
                maxCount: 10,
                knownItems: knownByID
            )

            guard !records.isEmpty else {
                continueWatchingItems = []
                progressByID = [:]
                return
            }

            var fractions: [MediaID: Double] = [:]
            for record in records where record.progress.duration > 0 {
                fractions[record.item.id] = record.fraction
            }
            progressByID = fractions
            continueWatchingItems = records.map(\.item)
        } catch is CancellationError {
            return
        } catch {
            continueWatchingItems = []
            progressByID = [:]
        }
    }
}
