import Foundation

public enum PosterSize: String, Sendable {
    case w185, w342, w500, w780
}

public struct ImageURLBuilder: Sendable {
    public var baseURL = URL(string: "https://image.tmdb.org/t/p")!

    public init() {}

    public func url(for path: String?, size: PosterSize) -> URL? {
        guard let path else { return nil }
        return baseURL.appendingPathComponent(size.rawValue).appendingPathComponent(path)
    }
}
