import Testing
@testable import SampleTVUI

struct ImageURLBuilderTests {
    @Test func buildsSizedURLFromLeadingSlashPath() {
        let url = ImageURLBuilder().url(for: "/abc.jpg", size: .w342)
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w342/abc.jpg")
    }

    @Test func buildsBackdropAndOriginalSizes() {
        let builder = ImageURLBuilder()
        #expect(builder.url(for: "/hero.jpg", size: .w780)?.absoluteString == "https://image.tmdb.org/t/p/w780/hero.jpg")
        #expect(
            builder.url(for: "hero.jpg", size: .w1280)?.absoluteString
                == "https://image.tmdb.org/t/p/w1280/hero.jpg"
        )
        #expect(
            builder.url(for: "/hero.jpg", size: .original)?.absoluteString
                == "https://image.tmdb.org/t/p/original/hero.jpg"
        )
    }

    @Test func passesThroughFullHTTPURL() {
        let full = "https://example.com/poster.png"
        #expect(ImageURLBuilder().url(for: full, size: .w342)?.absoluteString == full)
    }

    @Test func nilOrEmptyOrWhitespacePathsReturnNil() {
        let builder = ImageURLBuilder()
        #expect(builder.url(for: nil, size: .w342) == nil)
        #expect(builder.url(for: "", size: .w342) == nil)
        #expect(builder.url(for: "   \n\t ", size: .w1280) == nil)
        #expect(builder.url(for: "/", size: .w780) == nil)
    }
}
