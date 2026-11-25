import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVAPI

@Suite struct VideoDecodingTests {
    @Test func videoDTOMapsTrailerAndFeatureKinds() {
        let trailer = VideoDTO(id: "1", key: "k1", name: "Trailer", site: "YouTube", type: "Trailer", iso6391: "en")
        let feature = VideoDTO(id: "2", key: "k2", name: "Clip", site: "YouTube", type: "Behind the Scenes", iso6391: nil)

        #expect(trailer.videoKind == .trailer)
        #expect(feature.videoKind == .feature)
    }

    @Test func detailsDTOWithVideosDecodesTMDBResultsKey() async throws {
        let body = """
        {
            "id": 603,
            "title": "The Matrix",
            "overview": "x",
            "release_date": "1999-03-30",
            "vote_average": 8.2,
            "genres": [
                {"id": 28, "name": "Action"}
            ],
            "runtime": 136,
            "recommendations": {
                "results": [
                    {"id": 604, "title": "Reloaded", "release_date": "2003-05-15"}
                ]
            },
            "videos": {
                "results": [
                    {
                        "id": "trailer1",
                        "key": "abc123",
                        "name": "Official Trailer",
                        "site": "YouTube",
                        "type": "Trailer",
                        "iso_639_1": "en"
                    }
                ]
            }
        }
        """

        let stub = StubTransport([StubResponse(body: body)])
        let client = TMDBClient(configuration: TMDBConfiguration(readAccessToken: "t"), transport: stub)
        let details = try await TMDBMediaRepository(client: client).details(of: MediaID(kind: .movie, value: 603))

        #expect(details.videos.count == 1)
        #expect(details.videos[0].name == "Official Trailer")
        #expect(details.videos[0].kind == .trailer)
        #expect(details.videos[0].language == "en")
        #expect(details.recommendations.count == 1)
    }
}

@Suite struct CatalogPlaybackResourceResolverTests {
    @Test func resolveReturnsFeatureAndTrailerWithDistinctProgressTracking() async throws {
        let resolver = CatalogPlaybackResourceResolver()
        let resources = try await resolver.resolve(MediaID(kind: .movie, value: 603), genreIDs: [28])

        let feature = try #require(resources.first { $0.kind == .feature })
        let trailer = try #require(resources.first { $0.kind == .trailer })

        #expect(feature.trackProgress == true)
        #expect(trailer.trackProgress == false)
        #expect(feature.url != trailer.url)
    }

    @Test func resolveMapsDifferentIDsToDistinctStreams() async throws {
        let resolver = CatalogPlaybackResourceResolver()
        let first = try await resolver.resolve(MediaID(kind: .movie, value: 1), genreIDs: [])
        let second = try await resolver.resolve(MediaID(kind: .movie, value: 2), genreIDs: [])

        #expect(first.first?.url != second.first?.url)
    }
}
