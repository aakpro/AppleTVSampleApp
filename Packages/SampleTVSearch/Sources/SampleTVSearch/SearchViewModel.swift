import Observation
import SampleTVDomain

@MainActor
@Observable
public final class SearchViewModel {
    public enum State: Equatable {
        case idle
        case loaded([MediaItem])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var canLoadMore = false
    public var text = ""
    public var filter = MediaFilter(kind: .tv)

    private let search: SearchMedia
    private let debounce: Duration
    private var items: [MediaItem] = []
    private var nextPage = 1

    public init(search: SearchMedia, debounce: Duration = .milliseconds(300)) {
        self.search = search
        self.debounce = debounce
    }

    /// Drive from `.task(id: SearchKey(text:filter:))`. SwiftUI cancels the previous task when the
    /// input changes, so the sleep is the debounce and no Combine pipeline is needed.
    public func performSearch() async {
        do {
            try await Task.sleep(for: debounce)
            items = []
            nextPage = 1
            await loadNextPage()
        } catch {
            return // cancelled by newer input
        }
    }

    public func loadNextPage() async {
        guard SearchQuery(text) != nil else {
            state = .idle
            canLoadMore = false
            return
        }
        do {
            let page = try await search(text, kind: filter.kind, page: nextPage)
            items += page.items.filter(filter.matches)
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