import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct CategoryResultsView: View {
    private let discover: DiscoverMedia
    private let kind: MediaKind
    private let genre: Genre?
    private let onSelect: (MediaItem) -> Void

    @State private var sort: MediaSort = .popularity
    @State private var items: [MediaItem] = []
    @State private var nextPage = 1
    @State private var canLoadMore = false
    @State private var isLoading = false
    @State private var error: MediaError?

    public init(
        discover: DiscoverMedia,
        kind: MediaKind,
        genre: Genre? = nil,
        onSelect: @escaping (MediaItem) -> Void
    ) {
        self.discover = discover
        self.kind = kind
        self.genre = genre
        self.onSelect = onSelect
    }

    public var body: some View {
        content
            .navigationTitle(genre?.name ?? (kind == .movie ? "All Movies" : "All TV Shows"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Sort", selection: $sort) {
                        Text("Popular").tag(MediaSort.popularity)
                        Text("Top Rated").tag(MediaSort.rating)
                        Text("Newest").tag(MediaSort.newest)
                    }
                }
            }
            .task(id: sort) {
                await reload()
            }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading && items.isEmpty {
            ProgressView()
        } else if let error, items.isEmpty {
            ErrorView(error: error) { Task { await reload() } }
        } else {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240), spacing: 40)], spacing: 60) {
                    ForEach(items) { item in
                        Button { onSelect(item) } label: {
                            MediaCard(item: item)
                        }
                        .buttonStyle(.card)
                        .task {
                            if item == items.last, canLoadMore {
                                await loadNextPage()
                            }
                        }
                    }
                }
                .padding(60)
            }
        }
    }

    private func reload() async {
        items = []
        nextPage = 1
        canLoadMore = false
        error = nil
        isLoading = true
        await loadNextPage()
        isLoading = false
    }

    private func loadNextPage() async {
        let genreIDs: Set<Int> = genre.map { [$0.id] } ?? []
        let filter = MediaFilter(kind: kind, genreIDs: genreIDs, sort: sort)
        do {
            let page = try await discover(filter, page: nextPage)
            items += page.items
            nextPage = page.page + 1
            canLoadMore = page.hasNextPage
        } catch is CancellationError {
            return
        } catch {
            self.error = error as? MediaError ?? .unknown
        }
    }
}
