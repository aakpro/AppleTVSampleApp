import SampleTVDomain
import Testing
@testable import SampleTVUI

@MainActor
@Suite struct MediaCardTests {
    @Test func mediaCardInitializesWithDefaultProgress() {
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 1),
            title: "Test Movie"
        )
        let mediaCard = MediaCard(item: item)
        _ = mediaCard
    }

    @Test func mediaCardInitializesWithProgress() {
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 1),
            title: "Test Movie"
        )
        let mediaCard = MediaCard(item: item, playbackProgress: 0.5)
        _ = mediaCard
    }
}
