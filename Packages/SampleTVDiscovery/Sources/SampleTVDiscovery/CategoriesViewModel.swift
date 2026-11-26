import Foundation
import Observation
import SampleTVDomain

@MainActor
@Observable
public final class CategoriesViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded(movies: [Genre], tvShows: [Genre])
        case failed(MediaError)
    }

    private let getGenres: GetGenres

    public private(set) var state: State = .idle

    public init(getGenres: GetGenres) {
        self.getGenres = getGenres
    }

    public func load() async {
        guard state != .loading else { return }
        state = .loading

        do {
            async let moviesTask = getGenres(for: .movie)
            async let tvShowsTask = getGenres(for: .tv)
            let (movies, tvShows) = try await (moviesTask, tvShowsTask)
            state = .loaded(movies: movies, tvShows: tvShows)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }
}
