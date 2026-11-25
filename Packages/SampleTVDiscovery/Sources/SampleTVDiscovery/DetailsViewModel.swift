import Observation
import SampleTVDomain

@MainActor
@Observable
public final class DetailsViewModel {
    public enum State: Equatable {
        case loading
        case loaded(MediaDetails)
        case failed(MediaError)
    }

    public private(set) var state: State = .loading
    public private(set) var savedProgress: PlaybackProgress?
    public private(set) var playableResources: [PlayableResource] = []
    public let item: MediaItem

    public var resumeLabel: String {
        guard let savedProgress, !savedProgress.isWatched, savedProgress.position > 0 else {
            return "Play"
        }
        let totalSeconds = Int(savedProgress.position)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "Resume %02d:%02d", minutes, seconds)
    }

    public var featureResource: PlayableResource? {
        playableResources.first { $0.kind == .feature }
    }

    public var trailerResource: PlayableResource? {
        playableResources.first { $0.kind == .trailer }
    }

    private let getDetails: GetMediaDetails
    private let progressStore: (any PlaybackProgressStore)?
    private let resourceResolver: (any PlaybackResourceResolver)?

    public init(
        item: MediaItem,
        getDetails: GetMediaDetails,
        progressStore: (any PlaybackProgressStore)? = nil,
        resourceResolver: (any PlaybackResourceResolver)? = nil
    ) {
        self.item = item
        self.getDetails = getDetails
        self.progressStore = progressStore
        self.resourceResolver = resourceResolver
    }

    public func load() async {
        state = .loading
        do {
            let details = try await getDetails(item.id)
            state = .loaded(details)
            savedProgress = try? await progressStore?.loadProgress(for: item.id)
            if let resourceResolver {
                playableResources = (try? await resourceResolver.resolve(
                    item.id,
                    genreIDs: details.item.genreIDs
                )) ?? []
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }

    public func resolvePlayableResource(kind: PlaybackResourceKind) async throws -> PlayableResource? {
        if let cached = playableResources.first(where: { $0.kind == kind }) {
            return cached
        }
        guard case .loaded(let details) = state, let resourceResolver else { return nil }
        let resources = try await resourceResolver.resolve(item.id, genreIDs: details.item.genreIDs)
        playableResources = resources
        return resources.first { $0.kind == kind }
    }

    public func getPlayableResources() async throws -> [PlayableResource] {
        if !playableResources.isEmpty {
            return playableResources
        }
        guard case .loaded(let details) = state, let resourceResolver else { return [] }
        let resources = try await resourceResolver.resolve(item.id, genreIDs: details.item.genreIDs)
        playableResources = resources
        return resources
    }
}
