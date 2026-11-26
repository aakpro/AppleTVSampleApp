import Foundation

/// Port implemented by the data layer (`SampleTVAPI`). The domain only knows this protocol.
public protocol MediaRepository: Sendable {
    func discover(_ filter: MediaFilter, page: Int) async throws -> ResultPage<MediaItem>
    func search(_ query: SearchQuery, page: Int) async throws -> ResultPage<MediaItem>
    func details(of id: MediaID) async throws -> MediaDetails
    func genres(for kind: MediaKind) async throws -> [Genre]
}
