import SampleTVDomain
import SwiftUI
import Testing
@testable import SampleTVUI

@MainActor
@Suite struct MediaCardTests {
    @Test func mediaCardInitializesWithDefaultAndCustomMetadata() {
        let item = MediaItem(
            id: MediaID(kind: .movie, value: 1),
            title: "Test Movie",
            releaseYear: 2024,
            rating: 8.4,
            posterPath: "/poster.jpg"
        )
        let card = MediaCard(item: item)
        _ = card.body

        let missingYearItem = MediaItem(
            id: MediaID(kind: .tv, value: 2),
            title: "Show Without Year"
        )
        let cardWithAction = MediaCard(item: missingYearItem, playbackProgress: 0.45) {}
        _ = cardWithAction.body
    }

    @Test func posterImageAndMediaShelfRowInitializeCleanly() {
        let poster = PosterImage(url: nil, title: "Fallback Poster")
        _ = poster.body

        let items = [
            MediaItem(id: MediaID(kind: .movie, value: 10), title: "Alpha", releaseYear: 2023),
            MediaItem(id: MediaID(kind: .movie, value: 11), title: "Beta", rating: 7.9)
        ]
        let shelf = MediaShelfRow(
            title: "Trending",
            items: items,
            progressByID: [MediaID(kind: .movie, value: 10): 0.25],
            horizontalMargin: SampleTVTheme.horizontalSafeMargin
        ) { _ in }
        _ = shelf.body
    }
}
