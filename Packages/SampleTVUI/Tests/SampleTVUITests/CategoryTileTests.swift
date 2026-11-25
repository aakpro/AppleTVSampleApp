import Testing
@testable import SampleTVUI

@MainActor
@Suite struct CategoryTileTests {
    @Test func categoryTileInitializesWithoutCrashing() {
        let tile = CategoryTile(title: "Action") {}
        _ = tile
    }
}
