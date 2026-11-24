import Testing
@testable import SampleTVUI

struct ImageURLBuilderTests {
    @Test func buildsSizedURLFromLeadingSlashPath() {
        let url = ImageURLBuilder().url(for: "/abc.jpg", size: .w342)
        #expect(url?.absoluteString == "https://image.tmdb.org/t/p/w342/abc.jpg")
    }

    @Test func nilPathGivesNoURL() {
        #expect(ImageURLBuilder().url(for: nil, size: .w342) == nil)
    }
}