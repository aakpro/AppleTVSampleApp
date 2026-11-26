import Observation
import SampleTVDomain

@MainActor
@Observable
public final class SearchViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([MediaItem])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var canLoadMore = false
    public private(set) var availableGenres: [Genre] = []
    public var text = ""
    public var selectedKind: MediaKind? {
        didSet {
            if let selectedKind {
                filter.kind = selectedKind
            }
        }
    }
    public var filter = MediaFilter(kind: .tv)

    private let search: SearchMedia
    private let getGenres: GetGenres?
    private let debounce: Duration
    private var items: [MediaItem] = []
    private var nextPage = 1

    public init(
        search: SearchMedia,
        getGenres: GetGenres? = nil,
        debounce: Duration = .milliseconds(300)
    ) {
        self.search = search
        self.getGenres = getGenres
        self.debounce = debounce
    }

    public func loadGenres() async {
        guard let getGenres else { return }
        let kind = selectedKind ?? .movie
        availableGenres = (try? await getGenres(for: kind)) ?? []
    }

    /// Drive from `.task(id: Key(...))`. SwiftUI cancels the previous task when the
    /// input changes, so the sleep is the debounce and no Combine pipeline is needed.
    public func performSearch() async {
        guard SearchQuery(text) != nil else {
            items = []
            nextPage = 1
            canLoadMore = false
            state = .idle
            return
        }
        state = .loading
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
        if items.isEmpty {
            state = .loading
        }
        do {
            let page = try await search(text, kind: selectedKind, page: nextPage)
            items += page.items.filter(matchesCurrentFilter)
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
            state = .loaded(items)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }

    public func retry() async {
        items = []
        nextPage = 1
        await loadNextPage()
    }

    private func matchesCurrentFilter(_ item: MediaItem) -> Bool {
        if selectedKind != nil {
            return filter.matches(item)
        }
        if !filter.genreIDs.isEmpty, filter.genreIDs.isDisjoint(with: item.genreIDs) {
            return false
        }
        return true
    }
}
