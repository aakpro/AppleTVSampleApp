import Testing
@testable import SampleTVUI

@MainActor
@Suite struct CategoryTileTests {
    @Test func categoryTileInitializesWithDefaultAndCustomSymbols() {
        let tile = CategoryTile(title: "Action") {}
        _ = tile.body

        let custom = CategoryTile(title: "Sci-Fi Picks", systemImage: "sparkles") {}
        _ = custom.body
    }

    @Test func defaultSymbolMapsGenresAndFallsBack() {
        #expect(CategoryTile.defaultSymbol(for: "All Movies") == "film.stack")
        #expect(CategoryTile.defaultSymbol(for: "All TV Shows") == "tv")
        #expect(CategoryTile.defaultSymbol(for: "Action") == "flame.fill")
        #expect(CategoryTile.defaultSymbol(for: "Drama") == "theatermasks.fill")
        #expect(CategoryTile.defaultSymbol(for: "Comedy") == "face.smiling")
        #expect(CategoryTile.defaultSymbol(for: "Unknown Niche") == "film.fill")
    }
}
