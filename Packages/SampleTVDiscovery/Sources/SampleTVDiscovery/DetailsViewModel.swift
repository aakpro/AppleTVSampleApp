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

    public private(set) var isInWatchlist = false

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
    private let loadProgress: LoadPlaybackProgress?
    private let resolveResources: ResolvePlaybackResources?
    private let isInWatchlistUseCase: IsInWatchlist?
    private let toggleWatchlistUseCase: ToggleWatchlist?
    private let profileID: String

    public init(
        item: MediaItem,
        getDetails: GetMediaDetails,
        loadProgress: LoadPlaybackProgress? = nil,
        resolveResources: ResolvePlaybackResources? = nil,
        isInWatchlist: IsInWatchlist? = nil,
        toggleWatchlist: ToggleWatchlist? = nil,
        profileID: String = ViewerProfile.defaultID
    ) {
        self.item = item
        self.getDetails = getDetails
        self.loadProgress = loadProgress
        self.resolveResources = resolveResources
        self.isInWatchlistUseCase = isInWatchlist
        self.toggleWatchlistUseCase = toggleWatchlist
        self.profileID = profileID
    }

    public func load() async {
        state = .loading
        do {
            let details = try await getDetails(item.id)
            state = .loaded(details)
            savedProgress = try? await loadProgress?(for: item.id, profileID: profileID)
            if let resolveResources {
                playableResources = (try? await resolveResources(
                    item.id,
                    genreIDs: details.item.genreIDs
                )) ?? []
            }

            if let isInWatchlistUseCase {
                do {
                    isInWatchlist = try await isInWatchlistUseCase(item.id, for: profileID)
                } catch is CancellationError {
                    throw CancellationError()
                } catch {
                    isInWatchlist = false
                }
            } else {
                isInWatchlist = false
            }
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }

    public func toggleWatchlist() async {
        guard let toggleWatchlistUseCase else { return }

        do {
            isInWatchlist = try await toggleWatchlistUseCase(item, for: profileID)
        } catch is CancellationError {
            return
        } catch {
            // Keep current watchlist state if persistence fails.
        }
    }

    public func resolvePlayableResource(kind: PlaybackResourceKind) async throws -> PlayableResource? {
        if let cached = playableResources.first(where: { $0.kind == kind }) {
            return cached
        }
        guard case .loaded(let details) = state, let resolveResources else { return nil }
        let resources = try await resolveResources(item.id, genreIDs: details.item.genreIDs)
        playableResources = resources
        return resources.first { $0.kind == kind }
    }

    public func getPlayableResources() async throws -> [PlayableResource] {
        if !playableResources.isEmpty {
            return playableResources
        }
        guard case .loaded(let details) = state, let resolveResources else { return [] }
        let resources = try await resolveResources(item.id, genreIDs: details.item.genreIDs)
        playableResources = resources
        return resources
    }
}
