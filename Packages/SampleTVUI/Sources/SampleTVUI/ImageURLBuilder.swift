import Foundation

public enum PosterSize: String, Sendable {
    case w185, w300, w342, w500, w780, w1280, original
}

public struct ImageURLBuilder: Sendable {
    public var baseURL = URL(string: "https://image.tmdb.org/t/p")!

    public init() {}

    public func url(for path: String?, size: PosterSize) -> URL? {
        guard let path else { return nil }
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return URL(string: trimmed)
        }

        let cleanPath = trimmed.hasPrefix("/") ? String(trimmed.dropFirst()) : trimmed
        guard !cleanPath.isEmpty else { return nil }

        return baseURL.appendingPathComponent(size.rawValue).appendingPathComponent(cleanPath)
    }
}
