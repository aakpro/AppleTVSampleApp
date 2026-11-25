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
    public let item: MediaItem
    
    /// The resume label based on progress tracking.
    public var resumeLabel: String {
        // For now, simply return "Play" - we'll handle actual resume logic properly in the future
        return "Play"
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
            state = .loaded(try await getDetails(item.id))
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }
    
    /// Resolves the playable resource for the media item. Returns feature or trailer resources.
    public func resolvePlayableResource(kind: PlaybackResourceKind) async throws -> PlayableResource? {
        guard case .loaded(let details) = state else { return nil }
        
        // If we have a resolver, use it to resolve resources
        if let resourceResolver {
            let resources = try await resourceResolver.resolve(item.id, genreIDs: details.item.genreIDs)
            return resources.first { $0.kind == kind }
        }
        
        // Fallback case (this would normally not be reached in the real implementation)
        return nil
    }
    
    /// Gets all available playable resources for this media item.
    public func getPlayableResources() async throws -> [PlayableResource] {
        guard case .loaded(let details) = state else { return [] }
        
        if let resourceResolver {
            return try await resourceResolver.resolve(item.id, genreIDs: details.item.genreIDs)
        }
        
        // Fallback (this should not be reached in the real implementation)
        return []
    }
}
