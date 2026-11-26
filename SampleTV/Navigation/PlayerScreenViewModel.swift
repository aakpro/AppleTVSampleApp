import Foundation
import Observation
import SampleTVDomain

@MainActor
@Observable
final class PlayerScreenViewModel {
    let selection: PlaybackSelection
    private let loadProgress: LoadPlaybackProgress
    private let saveProgressUseCase: SavePlaybackProgress

    private(set) var initialPosition: TimeInterval?
    private(set) var isReady = false

    var url: URL { selection.resource.url }
    var title: String { selection.resource.title }
    var subtitle: String? { selection.resource.subtitle }

    init(
        selection: PlaybackSelection,
        loadProgress: LoadPlaybackProgress,
        saveProgress: SavePlaybackProgress
    ) {
        self.selection = selection
        self.loadProgress = loadProgress
        self.saveProgressUseCase = saveProgress
    }

    func load() async {
        if selection.resource.trackProgress {
            let saved = try? await loadProgress(
                for: selection.mediaID,
                profileID: selection.profileID
            )
            if let saved, !saved.isWatched {
                let episodeMatches = selection.episode == nil ||
                    (saved.seasonNumber == selection.episode?.seasonNumber &&
                     saved.episodeNumber == selection.episode?.episodeNumber)
                if episodeMatches {
                    initialPosition = saved.position
                }
            }
        }
        isReady = true
    }

    func saveProgress(position: TimeInterval, duration: TimeInterval) async {
        guard selection.resource.trackProgress else { return }
        let progress = PlaybackProgress(
            mediaID: selection.mediaID,
            position: position,
            duration: duration,
            profileID: selection.profileID,
            seasonNumber: selection.episode?.seasonNumber,
            episodeNumber: selection.episode?.episodeNumber
        )
        try? await saveProgressUseCase(progress)
    }
}
