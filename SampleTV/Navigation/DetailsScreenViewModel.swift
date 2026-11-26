import Foundation
import Observation
import SampleTVDomain

struct PlaybackSelection: Identifiable, Sendable {
    let id = UUID()
    let mediaID: MediaID
    let profileID: String
    let resource: PlayableResource
    let episode: TVEpisode?

    init(
        mediaID: MediaID,
        profileID: String,
        resource: PlayableResource,
        episode: TVEpisode? = nil
    ) {
        self.mediaID = mediaID
        self.profileID = profileID
        self.resource = resource
        self.episode = episode
    }
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

    func startPlayback(
        for item: MediaItem,
        episode: TVEpisode? = nil,
        kind: PlaybackResourceKind,
        trailerTitle: String? = nil
    ) async {
        let resolved = (try? await resolveResources.resolveFirst(
            item.id,
            genreIDs: item.genreIDs,
            episode: kind == .feature ? episode : nil,
            kind: kind
        )) ?? PlayableResource(
            url: fallbackURL(item),
            kind: kind,
            title: item.title,
            trackProgress: kind == .feature
        )

        // Set the proper metadata based on playback kind
        var updatedTitle = resolved.title
        var updatedSubtitle = resolved.subtitle

        if kind == .feature {
            updatedTitle = item.title
            if let episode {
                updatedSubtitle = "\(episode.episodeCode) · \(episode.name)"
            } else {
                updatedSubtitle = "Full Feature"
            }
        } else if kind == .trailer {
            updatedTitle = trailerTitle ?? "\(item.title) — Trailer"
            updatedSubtitle = item.title
        }

        // Update resource with proper metadata (keeping the original URL and trackProgress)
        let updatedResource = PlayableResource(
            url: resolved.url,
            kind: resolved.kind,
            title: updatedTitle,
            subtitle: updatedSubtitle,
            trackProgress: resolved.trackProgress
        )

        playbackSelection = PlaybackSelection(
            mediaID: item.id,
            profileID: profileID,
            resource: updatedResource,
            episode: episode
        )
    }
}
