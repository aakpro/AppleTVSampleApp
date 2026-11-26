import Foundation
import Observation
import SampleTVDomain

struct PlaybackSelection: Identifiable, Sendable {
    let id = UUID()
    let mediaID: MediaID
    let profileID: String
    let resource: PlayableResource
}

@MainActor
@Observable
final class DetailsScreenViewModel {
    private let resolveResources: ResolvePlaybackResources
    private let fallbackURL: @MainActor @Sendable (MediaItem) -> URL
    private let profileID: String

    var playbackSelection: PlaybackSelection?

    init(
        resolveResources: ResolvePlaybackResources,
        fallbackURL: @MainActor @Sendable @escaping (MediaItem) -> URL,
        profileID: String = ViewerProfile.defaultID
    ) {
        self.resolveResources = resolveResources
        self.fallbackURL = fallbackURL
        self.profileID = profileID
    }

    func startPlayback(for item: MediaItem, kind: PlaybackResourceKind) async {
        let resolved = (try? await resolveResources.resolveFirst(
            item.id,
            genreIDs: item.genreIDs,
            kind: kind
        )) ?? PlayableResource(
            url: fallbackURL(item),
            kind: kind,
            title: item.title,
            trackProgress: kind == .feature
        )
        playbackSelection = PlaybackSelection(
            mediaID: item.id,
            profileID: profileID,
            resource: resolved
        )
    }
}
