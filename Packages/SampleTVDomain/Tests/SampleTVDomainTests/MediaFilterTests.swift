import Testing
@testable import SampleTVDomain

struct MediaFilterTests {
    private func item(
        kind: MediaKind = .tv,
        year: Int? = 2010,
        genres: [Int] = [18],
        rating: Double? = 8
    ) -> MediaItem {
        MediaItem(
            id: MediaID(kind: kind, value: 1), title: "T", releaseYear: year,
            genreIDs: genres, rating: rating
        )
    }

    @Test func emptyFilterAcceptsAnyItemOfTheSameKind() {
        #expect(MediaFilter(kind: .tv).matches(item()))
        #expect(!MediaFilter(kind: .movie).matches(item()))
    }

    @Test func kindMismatchRejectsAll() {
        #expect(!MediaFilter(kind: .tv).matches(item(kind: .movie)))
        #expect(!MediaFilter(kind: .movie).matches(item(kind: .tv)))
    }

    @Test func emptyGenreSetAcceptsAnyItemOfSameKind() {
        let filter = MediaFilter(kind: .movie)
        #expect(filter.matches(item(kind: .movie, genreIDs: [100])))
    }

    @Test func nonEmptyGenreSetRequiresMatchingGenre() {
        let filter = MediaFilter(genreIDs: [18])
        #expect(!filter.matches(item(genres: [35])))
        #expect(filter.matches(item(genres: [18, 35])))
    }

    @Test func genreMatchesIfAnySelectedGenreIsPresent() {
        #expect(MediaFilter(genreIDs: [18, 35]).matches(item(genres: [35])))
        #expect(!MediaFilter(genreIDs: [80]).matches(item(genres: [35])))
    }

    @Test func yearAndRatingBoundsAreInclusive() {
        let filter = MediaFilter(years: 2010...2012, minimumRating: 8)
        #expect(filter.matches(item(year: 2010, rating: 8)))
        #expect(!filter.matches(item(year: 2013)))
        #expect(!filter.matches(item(rating: 7.9)))
        #expect(!filter.matches(item(year: nil)))
    }

    @Test func missingYearIsRejectedWhenRangeIsSet() {
        let filter = MediaFilter(years: 2010...2025)
        #expect(!filter.matches(item(year: nil, genres: [])))
    }

    @Test func missingRatingIsRejectedWhenMinimumIsSet() {
        let filter = MediaFilter(minimumRating: 8.0)
        #expect(!filter.matches(item(rating: nil, genreIDs: [])))
    }

    @Test func yearRangeIsClosed(bothBoundsInclusive) {
        let filter = MediaFilter(years: 2010...2025)
        #expect(filter.matches(item(year: 2010, genres: [])))
        #expect(filter.matches(item(year: 2025, genres: [])))
    }

    @Test func minimumRatingIsInclusive() {
        let filter = MediaFilter(minimumRating: 8.5)
        #expect(filter.matches(item(rating: 8.5, genreIDs: [])))
    }

    @Test func mismatchedKindRejectsEvenWithValidOtherCriteria() {
        let filter = MediaFilter(genreIDs: [35])
        #expect(!filter.matches(item(genres: [35], kind: .movie)))
    }

    @Test func multipleConditionsWorkTogether() {
        let filter = MediaFilter(
            genreIDs: [18, 35], years: 2015...2020, minimumRating: 7.5
        )
        #expect(filter.matches(item(year: 2018, rating: 7.5, genres: [35])))
    }
}
