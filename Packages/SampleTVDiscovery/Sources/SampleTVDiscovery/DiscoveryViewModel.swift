import Observation
import SampleTVDomain

@MainActor
@Observable
public final class DiscoveryViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([MediaShelf])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var canLoadMore = false
    public internal(set) var continueWatchingItems: [MediaItem] = []
    public internal(set) var progressByID: [MediaID: Double] = [:]
    public var filter: MediaFilter
    public var kind: MediaKind {
        didSet {
            filter.kind = kind
        }
    }

    var items: [MediaItem] {
        shelves.flatMap(\.items)
    }

    private let discover: DiscoverMedia
    private let getDiscoveryShelves: GetDiscoveryShelves?
    let getDetails: GetMediaDetails?
    let progressStore: (any PlaybackProgressStore)?
    private var shelves: [MediaShelf] = []
    private var nextPage = 1

    public init(
        discover: DiscoverMedia,
        getDiscoveryShelves: GetDiscoveryShelves? = nil,
        getDetails: GetMediaDetails? = nil,
        progressStore: (any PlaybackProgressStore)? = nil,
        filter: MediaFilter = MediaFilter(kind: .movie)
    ) {
        self.discover = discover
        self.getDiscoveryShelves = getDiscoveryShelves
        self.getDetails = getDetails
        self.progressStore = progressStore
        self.filter = filter
        self.kind = filter.kind
    }

    /// Reloads shelves from page 1. Call from `.task` and whenever `kind` or `filter` changes.
    public func reload() async {
        shelves = []
        nextPage = 1
        canLoadMore = false
        state = .loading
        await loadShelves()
    }

    private func loadShelves() async {
        do {
            if let getDiscoveryShelves {
                let loadedShelves = try await getDiscoveryShelves(for: kind)
                shelves = loadedShelves
                state = .loaded(loadedShelves)
            } else {
                let page = try await discover(filter, page: 1)
                nextPage = page.page + 1
                canLoadMore = page.hasNextPage
                let title = kind == .movie ? "Popular Movies" : "Popular TV Shows"
                let shelf = MediaShelf(id: "popular-\(kind.rawValue)", title: title, items: page.items)
                shelves = [shelf]
                state = .loaded(shelves)
            }
        } catch is CancellationError {
            return
        } catch {
            let mediaError = error as? MediaError ?? .unknown
            state = .failed(mediaError)
        }
    }

    public func loadNextPage() async {
        guard getDiscoveryShelves == nil else { return }
        do {
            let page = try await discover(filter, page: nextPage)
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
            if let first = shelves.first {
                shelves[0] = MediaShelf(id: first.id, title: first.title, items: first.items + page.items)
                state = .loaded(shelves)
            }
        } catch is CancellationError {
            return
        } catch {
            let mediaError = error as? MediaError ?? .unknown
            state = .failed(mediaError)
        }
    }
}
