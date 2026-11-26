import Observation
import SampleTVDomain

@MainActor
@Observable
public final class DetailsViewModel {
    public enum SeasonEpisodesState: Equatable, Sendable {
        case idle
        case loading
        case loaded(TVSeasonDetails)
        case failed(MediaError)

        public var loadedSeason: TVSeasonDetails? {
            if case .loaded(let details) = self { return details }
            return nil
        }
    }

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
    public private(set) var shouldAutoplayTrailer = false

    public private(set) var selectedSeasonNumber: Int?
    public private(set) var selectedEpisode: TVEpisode?
    public private(set) var seasonStates: [Int: SeasonEpisodesState] = [:]

    public var resumeLabel: String {
        if isSelectedEpisodeResumable, let savedProgress {
            let totalSeconds = Int(savedProgress.position)
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            let time = String(format: "%02d:%02d", minutes, seconds)
            if let episode = selectedEpisode {
                return "Resume \(episode.episodeCode) · \(time)"
            }
            return "Resume \(time)"
        }
        if let episode = selectedEpisode {
            return "Play \(episode.episodeCode)"
        }
        return "Play"
    }

    public var featureResource: PlayableResource? {
        playableResources.first { $0.kind == .feature }
    }

    public var trailerResource: PlayableResource? {
        playableResources.first { $0.kind == .trailer }
    }

    public var preferredTrailerTitle: String? {
        guard case .loaded(let details) = state else { return nil }
        if let trailer = details.videos.first(where: { $0.kind == .trailer }) {
            return trailer.name
        }
        return details.videos.first?.name
    }

    public var availableSeasons: [TVSeason] {
        guard case .loaded(let details) = state else { return [] }
        if !details.seasons.isEmpty {
            return details.seasons
        }
        if item.id.kind == .tv, let count = details.seasonCount, count > 0 {
            return (1...count).map { TVSeason(id: $0, seasonNumber: $0, name: "Season \($0)") }
        }
        return []
    }

    public var selectedSeasonState: SeasonEpisodesState {
        selectedSeasonNumber.flatMap { seasonStates[$0] } ?? .idle
    }

    public var selectedSeasonEpisodes: [TVEpisode] {
        selectedSeasonState.loadedSeason?.episodes ?? []
    }

    public var isSelectedEpisodeResumable: Bool {
        guard let savedProgress, !savedProgress.isWatched, savedProgress.position > 0 else {
            return false
        }
        guard item.id.kind == .tv else { return true }

        guard let savedSeason = savedProgress.seasonNumber,
              let savedEpisode = savedProgress.episodeNumber else {
            return true
        }
        if let selectedEpisode {
            return savedSeason == selectedEpisode.seasonNumber
                && savedEpisode == selectedEpisode.episodeNumber
        }
        return selectedSeasonNumber == savedSeason
    }

    private let getDetails: GetMediaDetails
    private let loadProgress: LoadPlaybackProgress?
    private let resolveResources: ResolvePlaybackResources?
    private let isInWatchlistUseCase: IsInWatchlist?
    private let toggleWatchlistUseCase: ToggleWatchlist?
    private let getPreferences: GetUserPreferences?
    private let getSeasonDetails: GetTVSeasonDetails?
    private let profileID: String

    public init(
        item: MediaItem,
        getDetails: GetMediaDetails,
        loadProgress: LoadPlaybackProgress? = nil,
        resolveResources: ResolvePlaybackResources? = nil,
        isInWatchlist: IsInWatchlist? = nil,
        toggleWatchlist: ToggleWatchlist? = nil,
        getPreferences: GetUserPreferences? = nil,
        getSeasonDetails: GetTVSeasonDetails? = nil,
        profileID: String = ViewerProfile.defaultID
    ) {
        self.item = item
        self.getDetails = getDetails
        self.loadProgress = loadProgress
        self.resolveResources = resolveResources
        self.isInWatchlistUseCase = isInWatchlist
        self.toggleWatchlistUseCase = toggleWatchlist
        self.getPreferences = getPreferences
        self.getSeasonDetails = getSeasonDetails
        self.profileID = profileID
    }

    public func load() async {
        state = .loading
        shouldAutoplayTrailer = false
        selectedSeasonNumber = nil
        selectedEpisode = nil
        seasonStates = [:]

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

            if let getPreferences,
               let prefs = try? await getPreferences(profileID: profileID) {
                let hasTrailer = trailerResource != nil || !details.videos.isEmpty
                shouldAutoplayTrailer = prefs.autoplayTrailers && hasTrailer
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

            await loadInitialSeasonIfNeeded()
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

    public func selectSeason(_ seasonNumber: Int) async {
        selectedSeasonNumber = seasonNumber
        if let cached = seasonStates[seasonNumber]?.loadedSeason {
            selectPreferredEpisode(in: cached, preferredEpisodeNumber: savedPreferredEpisode(for: seasonNumber))
            return
        }
        selectedEpisode = nil
        await loadSeason(number: seasonNumber, preferredEpisodeNumber: savedPreferredEpisode(for: seasonNumber))
    }

    public func retrySelectedSeason() async {
        guard let season = selectedSeasonNumber else { return }
        seasonStates[season] = nil
        await loadSeason(number: season, preferredEpisodeNumber: savedPreferredEpisode(for: season))
    }

    public func selectEpisode(_ episode: TVEpisode) {
        selectedSeasonNumber = episode.seasonNumber
        selectedEpisode = episode
    }

    public func resolvePlayableResource(
        kind: PlaybackResourceKind,
        episode: TVEpisode? = nil
    ) async throws -> PlayableResource? {
        if episode == nil, let cached = playableResources.first(where: { $0.kind == kind }) {
            return cached
        }
        guard case .loaded(let details) = state, let resolveResources else { return nil }
        let resources = try await resolveResources(item.id, genreIDs: details.item.genreIDs, episode: episode)
        if episode == nil {
            playableResources = resources
        }
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

    private func loadInitialSeasonIfNeeded() async {
        guard item.id.kind == .tv, !availableSeasons.isEmpty else { return }

        let initialSeason: Int? = {
            if let savedSeason = savedProgress?.seasonNumber,
               availableSeasons.contains(where: { $0.seasonNumber == savedSeason }) {
                return savedSeason
            }
            return availableSeasons.first(where: { $0.seasonNumber > 0 })?.seasonNumber
                ?? availableSeasons.first?.seasonNumber
        }()

        guard let initialSeason else { return }
        selectedSeasonNumber = initialSeason
        await loadSeason(
            number: initialSeason,
            preferredEpisodeNumber: savedPreferredEpisode(for: initialSeason)
        )
    }

    private func savedPreferredEpisode(for seasonNumber: Int) -> Int? {
        guard let savedProgress,
              !savedProgress.isWatched,
              savedProgress.seasonNumber == seasonNumber else {
            return nil
        }
        return savedProgress.episodeNumber
    }

    private func loadSeason(number: Int, preferredEpisodeNumber: Int?) async {
        if let cached = seasonStates[number]?.loadedSeason {
            if selectedSeasonNumber == number {
                selectPreferredEpisode(in: cached, preferredEpisodeNumber: preferredEpisodeNumber)
            }
            return
        }
        guard let getSeasonDetails else { return }

        seasonStates[number] = .loading
        do {
            let seasonDetails = try await getSeasonDetails(of: item.id, seasonNumber: number)
            seasonStates[number] = .loaded(seasonDetails)
            if selectedSeasonNumber == number {
                selectPreferredEpisode(in: seasonDetails, preferredEpisodeNumber: preferredEpisodeNumber)
            }
        } catch is CancellationError {
            if case .loading = seasonStates[number] {
                seasonStates[number] = .idle
            }
            return
        } catch {
            seasonStates[number] = .failed(error as? MediaError ?? .unknown)
        }
    }

    private func selectPreferredEpisode(in seasonDetails: TVSeasonDetails, preferredEpisodeNumber: Int?) {
        if let preferredEpisodeNumber,
           let match = seasonDetails.episodes.first(where: { $0.episodeNumber == preferredEpisodeNumber }) {
            selectedEpisode = match
        } else {
            selectedEpisode = seasonDetails.episodes.first
        }
    }
}
