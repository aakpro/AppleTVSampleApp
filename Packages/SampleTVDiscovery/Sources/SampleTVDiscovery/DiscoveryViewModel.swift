import Observation
import SampleTVDomain
import SampleTVPlaybackProgress

@MainActor
@Observable
public final class DiscoveryViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([MediaItem])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var canLoadMore = false
    public var filter: MediaFilter
    
    private let discover: DiscoverMedia
    private let progressStore: any PlaybackProgressStore
    private var items: [MediaItem] = []
    private var nextPage = 1

    public init(discover: DiscoverMedia, progressStore: any PlaybackProgressStore, filter: MediaFilter = MediaFilter()) {
        self.discover = discover
        self.progressStore = progressStore
        self.filter = filter
    }

    /// Reloads from page 1. Call from `.task` and whenever `filter` changes.
    public func reload() async {
        items = []
        nextPage = 1
        canLoadMore = false
        state = .loading
        await loadNextPage()
    }

    public func loadNextPage() async {
        do {
            let page = try await discover(filter, page: nextPage)
            items += page.items
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
            state = .loaded(items)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }
    
    /// Returns items to display in the Continue Watching section 
    public var continueWatchingItems: [MediaItem] {
        // This will be implemented separately - we need to load recently watched items 
        // from progress store and match with available media items
        return []
    } 
    
    /// Get all items that should appear (Continue Watching + regular discovery)
    public func allItems() async -> [MediaItem] {
        if case .loaded(let loadedItems) = state {
            return loadedItems
        }
        return []
    }
}
