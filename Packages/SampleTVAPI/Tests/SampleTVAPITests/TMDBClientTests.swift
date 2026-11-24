import Foundation
import Testing
import SampleTVDomain
@testable import SampleTVAPI

struct StubResponse: Sendable {
    var status = 200
    var body = "{}"
    var headers: [String: String] = [:]
}

actor StubTransport: HTTPTransport {
    private var responses: [StubResponse]
    private(set) var requests: [URLRequest] = []

    init(_ responses: [StubResponse]) {
        self.responses = responses
    }

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        requests.append(request)
        let next = responses.removeFirst()
        guard let url = request.url,
              let response = HTTPURLResponse(
                  url: url, statusCode: next.status, httpVersion: nil, headerFields: next.headers
              )
        else { throw MediaError.unknown }
        return (Data(next.body.utf8), response)
    }
}

private let tvPage = """
{"page":1,"total_pages":3,"results":[
 {"id":1396,"name":"Breaking Bad","first_air_date":"2008-01-20","genre_ids":[18],"vote_average":8.9,"poster_path":"/p.jpg"}
]}
"""

struct TMDBClientTests {
    private func repository(_ stub: StubTransport) -> TMDBMediaRepository {
        let client = TMDBClient(
            configuration: TMDBConfiguration(readAccessToken: "token"),
            transport: stub,
            retryPolicy: RetryPolicy(maxAttempts: 3, baseDelay: .milliseconds(1))
        )
        return TMDBMediaRepository(client: client)
    }

    @Test func discoverMapsTVResultsAndSendsBearerToken() async throws {
        let stub = StubTransport([StubResponse(body: tvPage)])
        let filter = MediaFilter(kind: .tv, genreIDs: [18])
        let page = try await repository(stub).discover(filter, page: 1)
        #expect(page.items.first?.title == "Breaking Bad")
        #expect(page.items.first?.releaseYear == 2008)
        #expect(page.items.first?.id == MediaID(kind: .tv, value: 1396))
        #expect(page.hasNextPage)
        let request = try #require(await stub.requests.first)
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer token")
        #expect(request.url?.query?.contains("with_genres=18") == true)
    }

    @Test func retriesOn429ThenSucceeds() async throws {
        let stub = StubTransport([
            StubResponse(status: 429, headers: ["Retry-After": "0"]),
            StubResponse(body: tvPage)
        ])
        let page = try await repository(stub).discover(MediaFilter(), page: 1)
        #expect(page.items.count == 1)
        #expect(await stub.requests.count == 2)
    }

    @Test func mapsStatusCodesWithoutRetryingClientErrors() async throws {
        let stub = StubTransport([StubResponse(status: 404)])
        await #expect(throws: MediaError.notFound) {
            _ = try await repository(stub).discover(MediaFilter(), page: 1)
        }
        #expect(await stub.requests.count == 1)
    }

    @Test func searchMultiDropsPeople() async throws {
        let body = """
        {"page":1,"total_pages":1,"results":[
         {"id":1,"media_type":"person","name":"Someone"},
         {"id":2,"media_type":"movie","title":"Heat","release_date":"1995-12-15"}]}
        """
        let stub = StubTransport([StubResponse(body: body)])
        let page = try await repository(stub).search(try #require(SearchQuery("heat")), page: 1)
        #expect(page.items.map(\.title) == ["Heat"])
    }
}

struct DetailsMappingTests {
    @Test func detailsDecodeGenresRuntimeAndRecommendations() async throws {
        let body = """
        {"id":603,"title":"The Matrix","overview":"x","release_date":"1999-03-30","vote_average":8.2,
         "genres":[{"id":28,"name":"Action"},{"id":878,"name":"Science Fiction"}],"runtime":136,
         "recommendations":{"results":[{"id":604,"title":"Reloaded","release_date":"2003-05-15"}]}}
        """
        let stub = StubTransport([StubResponse(body: body)])
        let client = TMDBClient(configuration: TMDBConfiguration(readAccessToken: "t"), transport: stub)
        let id = MediaID(kind: .movie, value: 603)
        let details = try await TMDBMediaRepository(client: client).details(of: id)
        #expect(details.item.title == "The Matrix")
        #expect(details.genres.map(\.name) == ["Action", "Science Fiction"])
        #expect(details.runtimeMinutes == 136)
        #expect(details.recommendations.map(\.title) == ["Reloaded"])
        let request = try #require(await stub.requests.first)
        #expect(request.url?.path.hasSuffix("/movie/603") == true)
    }
}