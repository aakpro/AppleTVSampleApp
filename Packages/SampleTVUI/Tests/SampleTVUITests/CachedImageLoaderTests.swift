import Foundation
import Testing
import UIKit
@testable import SampleTVUI

@Suite(.serialized)
struct CachedImageLoaderTests {
    @Test func loadImageDecodesValidPNGAndThrowsOnHTTPErrorOrBadData() async throws {
        let validURL = try #require(URL(string: "https://mock.sampletv.local/valid.png"))
        let invalidDataURL = try #require(URL(string: "https://mock.sampletv.local/corrupt.png"))
        let errorURL = try #require(URL(string: "https://mock.sampletv.local/missing.png"))

        let pngData = makeOneByOnePNGData()
        StubImageURLProtocol.configure(responses: [
            validURL: (200, pngData),
            invalidDataURL: (200, Data("not-an-image".utf8)),
            errorURL: (404, Data())
        ])

        let config = URLSessionConfiguration.ephemeral
        config.urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 0)
        config.protocolClasses = [StubImageURLProtocol.self]
        let session = URLSession(configuration: config)
        let loader = CachedImageLoader(urlSession: session)

        async let first = loader.loadUIImage(from: validURL)
        async let second = loader.loadUIImage(from: validURL)
        let (image1, image2) = try await (first, second)
        #expect(image1.size.width > 0)
        #expect(image2.size.width > 0)
        #expect(StubImageURLProtocol.hitCount(for: validURL) == 1)

        await #expect(throws: URLError.self) {
            _ = try await loader.loadUIImage(from: invalidDataURL)
        }

        await #expect(throws: URLError.self) {
            _ = try await loader.loadUIImage(from: errorURL)
        }
    }

    private func makeOneByOnePNGData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        let image = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        return image.pngData() ?? Data()
    }
}

private final class StubImageResponseBox: @unchecked Sendable {
    private let lock = NSLock()
    private var responses: [URL: (Int, Data)] = [:]
    private var hits: [URL: Int] = [:]

    func setResponses(_ value: [URL: (Int, Data)]) {
        lock.lock()
        responses = value
        hits = [:]
        lock.unlock()
    }

    func recordHitAndResponse(for url: URL) -> (Int, Data)? {
        lock.lock()
        defer { lock.unlock() }
        hits[url, default: 0] += 1
        return responses[url]
    }

    func hitCount(for url: URL) -> Int {
        lock.lock()
        defer { lock.unlock() }
        return hits[url, default: 0]
    }
}

private class StubImageURLProtocol: URLProtocol, @unchecked Sendable {
    private static let box = StubImageResponseBox()

    static func configure(responses: [URL: (Int, Data)]) {
        box.setResponses(responses)
    }

    static func hitCount(for url: URL) -> Int {
        box.hitCount(for: url)
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let (status, data) = Self.box.recordHitAndResponse(for: url) ?? (404, Data())
        if let response = HTTPURLResponse(
            url: url,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        ) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowedInMemoryOnly)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
        }
    }

    override func stopLoading() {}
}
