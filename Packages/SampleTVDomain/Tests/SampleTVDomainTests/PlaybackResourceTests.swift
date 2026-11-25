import Foundation
import Testing
@testable import SampleTVDomain

@Suite struct PlaybackResourceTests {
    @Test func videoKindIsCodableAndHashable() throws {
        let videoKind = VideoKind.trailer
        #expect(videoKind == .trailer)

        let encoded = try JSONEncoder().encode(videoKind)
        let decoded = try JSONDecoder().decode(VideoKind.self, from: encoded)
        #expect(decoded == .trailer)
    }

    @Test func mediaVideoIsIdentifiableAndCodable() throws {
        let video = MediaVideo(
            id: "123",
            kind: .trailer,
            name: "Official Trailer",
            site: "YouTube",
            key: "abc123",
            language: "en"
        )

        #expect(video.id == "123")
        #expect(video.kind == .trailer)
        #expect(video.name == "Official Trailer")

        let encoded = try JSONEncoder().encode(video)
        let decoded = try JSONDecoder().decode(MediaVideo.self, from: encoded)
        #expect(decoded == video)
    }

    @Test func mediaDetailsIncludesVideosProperty() {
        let item = MediaItem(id: MediaID(kind: .movie, value: 123), title: "Test Movie")
        let details = MediaDetails(
            item: item,
            videos: [
                MediaVideo(
                    id: "trailer1",
                    kind: .trailer,
                    name: "Trailer",
                    site: "YouTube",
                    key: "trailer_key",
                    language: "en"
                )
            ]
        )

        #expect(details.videos.count == 1)
        #expect(details.videos[0].name == "Trailer")
    }

    @Test func playableResourceIsSendableAndEquatable() throws {
        let url = try #require(URL(string: "https://example.com/video.mp4"))
        let resource = PlayableResource(
            url: url,
            kind: .feature,
            title: "Test Feature",
            subtitle: "Subtitle",
            trackProgress: true
        )

        #expect(resource.url == url)
        #expect(resource.kind == .feature)
        #expect(resource.title == "Test Feature")
        #expect(resource.subtitle == "Subtitle")
        #expect(resource.trackProgress == true)
    }
}
