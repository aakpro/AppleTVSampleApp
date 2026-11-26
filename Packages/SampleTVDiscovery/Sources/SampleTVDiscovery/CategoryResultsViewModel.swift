import Foundation
import Observation
import SampleTVDomain
import SampleTVUI

@MainActor
@Observable
public final class CategoryResultsViewModel {
    public let kind: MediaKind
    public let genre: Genre?
    public var sort: MediaSort

    private let discover: DiscoverMedia
    private let pagination = PaginationController<MediaItem>()

    public var state: PaginationController<MediaItem>.State { pagination.state }
    public var items: [MediaItem] { pagination.items }
    public var canLoadMore: Bool { pagination.canLoadMore }
    public var isLoadingNextPage: Bool { pagination.isLoadingNextPage }
    public var error: MediaError? { pagination.error }

    public init(
        discover: DiscoverMedia,
        kind: MediaKind,
        genre: Genre? = nil,
        sort: MediaSort = .popularity
    ) {
        self.discover = discover
        self.kind = kind
        self.genre = genre
        self.sort = sort
    }

    public func reload() async {
        let filter = makeFilter()
        await pagination.reload { [discover] page in
            try await discover(filter, page: page)
        }
    }

    public func loadNextPage() async {
        let filter = makeFilter()
        await pagination.loadNextPage { [discover] page in
            try await discover(filter, page: page)
        }
    }

    private func makeFilter() -> MediaFilter {
        let genreIDs: Set<Int> = genre.map { [$0.id] } ?? []
        return MediaFilter(kind: kind, genreIDs: genreIDs, sort: sort)
    }
}
