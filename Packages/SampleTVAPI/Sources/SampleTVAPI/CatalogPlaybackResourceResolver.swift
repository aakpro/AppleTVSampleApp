import Foundation
import SampleTVDomain

/// Deterministically maps media IDs and genres to a curated catalog of public-domain / Creative Commons streams.
public struct CatalogPlaybackResourceResolver: PlaybackResourceResolver {
    private struct StreamEntry: Sendable {
        let title: String
        let featureURLString: String
        let trailerURLString: String
    }

    private static let catalog: [StreamEntry] = [
        StreamEntry(
            title: "Sintel",
            featureURLString: "https://bitdash-a.akamaihd.net/content/sintel/hls/playlist.m3u8",
            trailerURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
        ),
        StreamEntry(
            title: "Tears of Steel",
            featureURLString: "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8",
            trailerURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
        ),
        StreamEntry(
            title: "Big Buck Bunny",
            featureURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            trailerURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
        ),
        StreamEntry(
            title: "Elephants Dream",
            featureURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            trailerURLString: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoy.mp4"
        ),
        StreamEntry(
            title: "Apple Advanced Stream",
            featureURLString: "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8",
            trailerURLString: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"
        )
    ]

    public init() {}

    public func resolve(_ mediaID: MediaID, genreIDs: [Int]) async throws -> [PlayableResource] {
        let seed = abs(mediaID.value + (genreIDs.first ?? 0) + (mediaID.kind == .tv ? 1 : 0))
        let entry = Self.catalog[seed % Self.catalog.count]

        var resources: [PlayableResource] = []
        if let featureURL = URL(string: entry.featureURLString) {
            resources.append(PlayableResource(
                url: featureURL,
                kind: .feature,
                title: entry.title,
                subtitle: "Full Feature",
                trackProgress: true
            ))
        }
        if let trailerURL = URL(string: entry.trailerURLString) {
            resources.append(PlayableResource(
                url: trailerURL,
                kind: .trailer,
                title: "\(entry.title) — Trailer",
                subtitle: "Preview",
                trackProgress: false
            ))
        }
        return resources
    }
}
