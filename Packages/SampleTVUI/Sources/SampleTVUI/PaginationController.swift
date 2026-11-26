import Foundation
import Observation
import SampleTVDomain

@MainActor
@Observable
public final class PaginationController<Element: Sendable & Equatable> {
    public enum State: Equatable {
        case idle
        case loading
        case loaded([Element])
        case failed(MediaError)
    }

    public private(set) var state: State = .idle
    public private(set) var items: [Element] = []
    public private(set) var canLoadMore = false
    public private(set) var isLoading = false
    public private(set) var isLoadingNextPage = false
    public private(set) var error: MediaError?
    public private(set) var nextPage = 1

    public init() {}

    public func reset() {
        items = []
        canLoadMore = false
        isLoading = false
        isLoadingNextPage = false
        error = nil
        nextPage = 1
        state = .idle
    }

    public func reload(fetch: @MainActor (Int) async throws -> ResultPage<Element>) async {
        items = []
        canLoadMore = false
        nextPage = 1
        error = nil
        isLoading = true
        isLoadingNextPage = false
        state = .loading

        do {
            let page = try await fetch(1)
            items = page.items
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
            isLoading = false
            state = .loaded(items)
        } catch is CancellationError {
            isLoading = false
            return
        } catch {
            let mediaError = error as? MediaError ?? .unknown
            self.error = mediaError
            isLoading = false
            state = .failed(mediaError)
        }
    }

    public func loadNextPage(fetch: @MainActor (Int) async throws -> ResultPage<Element>) async {
        guard canLoadMore, !isLoading, !isLoadingNextPage else { return }

        isLoadingNextPage = true
        defer { isLoadingNextPage = false }

        do {
            let page = try await fetch(nextPage)
            items.append(contentsOf: page.items)
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
            error = nil
            state = .loaded(items)
        } catch is CancellationError {
            return
        } catch {
            let mediaError = error as? MediaError ?? .unknown
            self.error = mediaError
            canLoadMore = false
            if items.isEmpty {
                state = .failed(mediaError)
            }
        }
    }
}
