import Testing
@testable import SampleTVAPI

private class FakeTransport: Sendable, HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let mockResponse = Data()
        return (mockResponse, nil)
    }
}

func testTMDBClient<T>() async where T: Codable & Sendable {
    let config = TMDBConfiguration(readAccessToken: "test_token")
    
    struct MockMovieDTO: Codable, Sendable {
        var id: Int = 1
        var title: String = "Test Movie"
    }
    
    let client = TMDBClient(config: config, transport: FakeTransport())
}
