import Foundation

public struct GetGenres: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    public func callAsFunction(for kind: MediaKind) async throws -> [Genre] {
        try await repository.genres(for: kind)
    }
}

public struct GetDiscoveryShelves: Sendable {
    private let repository: any MediaRepository

    public init(repository: any MediaRepository) {
        self.repository = repository
    }

    private struct ShelfRequest: Sendable {
        let index: Int
        let id: String
        let title: String
        let filter: MediaFilter
    }

    public func callAsFunction(for kind: MediaKind, maxGenres: Int = 5) async throws -> [MediaShelf] {
        let genres = try await repository.genres(for: kind)
        let requests = makeRequests(for: kind, genres: genres, maxGenres: maxGenres)
        let indexedShelves = await fetchShelves(for: requests)
        return indexedShelves
            .sorted { $0.0 < $1.0 }
            .map(\.1)
    }

    private func makeRequests(
        for kind: MediaKind,
        genres: [Genre],
        maxGenres: Int
    ) -> [ShelfRequest] {
        var requests: [ShelfRequest] = [
            ShelfRequest(
                index: 0,
                id: "popular",
                title: "Popular",
                filter: MediaFilter(kind: kind, sort: .popularity)
            ),
            ShelfRequest(
                index: 1,
                id: "top-rated",
                title: "Top Rated",
                filter: MediaFilter(kind: kind, sort: .rating)
            ),
            ShelfRequest(
                index: 2,
                id: "new-releases",
                title: "New Releases",
                filter: MediaFilter(kind: kind, sort: .newest)
            )
        ]

        for (offset, genre) in genres.prefix(maxGenres).enumerated() {
            requests.append(ShelfRequest(
                index: 3 + offset,
                id: "genre-\(genre.id)",
                title: genre.name,
                filter: MediaFilter(kind: kind, genreIDs: [genre.id])
            ))
        }
        return requests
    }

    private func fetchShelves(for requests: [ShelfRequest]) async -> [(Int, MediaShelf)] {
        await withTaskGroup(
            of: (Int, MediaShelf?).self,
            returning: [(Int, MediaShelf)].self
        ) { group in
            for request in requests {
                group.addTask {
                    await fetchShelf(for: request)
                }
            }

            var results: [(Int, MediaShelf)] = []
            for await (index, shelf) in group {
                if let shelf {
                    results.append((index, shelf))
                }
            }
            return results
        }
    }

    private func fetchShelf(for request: ShelfRequest) async -> (Int, MediaShelf?) {
        do {
            let page = try await repository.discover(request.filter, page: 1)
            guard !page.items.isEmpty else { return (request.index, nil) }
            let shelf = MediaShelf(id: request.id, title: request.title, items: page.items)
            return (request.index, shelf)
        } catch {
            return (request.index, nil)
        }
    }
}
