import Foundation

public enum MediaError: Error, Equatable, Sendable {
    case offline
    case unauthorized
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case server(statusCode: Int)
    case decoding
    case unknown
}
