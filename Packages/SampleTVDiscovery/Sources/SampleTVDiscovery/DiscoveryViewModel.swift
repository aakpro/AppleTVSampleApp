import Observation
import SampleTVDomain

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
    public internal(set) var continueWatchingItems: [MediaItem] = []
    public var filter: MediaFilter

    private let discover: DiscoverMedia
    let getDetails: GetMediaDetails?
    let progressStore: (any PlaybackProgressStore)?
    var items: [MediaItem] = []
    private var nextPage = 1

    public init(
        discover: DiscoverMedia,
        getDetails: GetMediaDetails? = nil,
        progressStore: (any PlaybackProgressStore)? = nil,
        filter: MediaFilter = MediaFilter()
    ) {
        self.discover = discover
        self.getDetails = getDetails
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
}
