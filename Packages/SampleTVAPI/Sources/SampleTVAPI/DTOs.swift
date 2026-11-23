import Foundation

/// A generic TMDB item wrapper for API responses.
public struct MediaItemDTO: Codable, Sendable {
    public var id: Int?
    public var title: String?
    public var overview: String?
    public var year: Int?
    public var genreIDs: [Int]?
    public var rating: Double?
    public var posterPath: String?
    public var backdropPath: String?
    public var mediaType: MediaKindDTO
    
    public init(
        id: Int?, title: String?, overview: String?,
        year: Int?, genreIDs: [Int]?, rating: Double?,
        posterPath: String?, backdropPath: String?) -> Self {
        self.id = id
        self.title = title
        self.overview = overview
        self.year = year
        self.genreIDs = genreIDs
        self.rating = rating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
    }
}

public extension MediaItemDTO {
    var kind: Int { return mediaType.rawValue }
}

/// A DTO representing the TMDB API search result structure.
public struct SearchResultDTO: Codable, Sendable {
    public var id: Int?
    public var title: String?
    public var overview: String?
    public var year: Int?
    public var posterPath: String?
    public var backdropPath: String?
    
    /// Determines if this is a movie or TV show.
    public var movie: Bool
    public var tvShow: Bool
    
    public init(id: Int?, title: String?, overview: String?, year: Int?, posterPath: String?, backdropPath: String?) {
        self.id = id
        self.title = title
        self.overview = overview
        self.year = year
        self.posterPath = posterPath
        self.backdropPath = backdropPath
    }
}

/// A TMDB media details response DTO.
public struct MediaDetailsDTO: Codable, Sendable {
    public var id: Int?
    public var title: String?
    public var overview: String?
    public var year: Int?
    public var genreIDs: [Int]?
    public var backdropPath: String?
    
    /// Additional details specific to the media type.
    public var popularity: Double?
    public var voteAverage: Double?
    
    public init(
        id: Int?, title: String?, overview: String?, year: Int?, genreIDs: [Int]?,
        backdropPath: String?, popularity: Double?, voteAverage: Double?
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.year = year
        self.genreIDs = genreIDs
        self.backdropPath = backdropPath
        self.popularity = popularity
        self.voteAverage = voteAverage
    }
}

/// Mapping from DTO results to Domain entities.
public extension MediaItemDTO {
    init(data: Any?) throws -> Self? {
        guard let dictionary = data as? [String: Any] else { return nil }
        
        do {
            self.init(
                id: dictionary["id"] as? Int,
                title: dictionary["title"] as? String,
                overview: dictionary["overview"] as? String,
                year: dictionary["year"] as? Int,
                genreIDs: (dictionary["genre_ids"] as? [[String: Any]])?.first?.value as? [Int],
                rating: dictionary["vote_average"] as? Double,
                posterPath: dictionary["poster_path"] as? String,
                backdropPath: dictionary["backdrop_path"] as? String
            )
        } catch {
            return nil // Tolerant mapping - one missing field doesn't fail
        }
    }
}

public extension MediaItemDTO where Self.Type == TMDBMediaID<Kind> {
    init(from data: Any?) throws -> Self? {
        guard let dictionary = data as? [String: Any] else { return nil }
        
        do {
            self.init(
                id: dictionary["id"] as? Int,
                title: dictionary["title"] as? String,
                overview: dictionary["overview"] as? String,
                year: dictionary["year"] as? Int,
                posterPath: dictionary["poster_path"] as? String,
                backdropPath: dictionary["backdrop_path"] as? String
            )
        } catch {
            return nil
        }
    }
}

/// Represents the first four characters of a date string (e.g., "2010").
public struct ReleaseYear: Sendable {
    public let value: Int
    
    public init(value: Int) {
        self.value = value
    }
    
    /// Extracts the year from TMDB's API response date format.
    static func extract(from dateString: String?) -> ReleaseYear? {
        guard let first4 = Array(dateString?.characters ?? "").prefix(4).first else { return nil }
        
        do {
            return ReleaseYear(value: Int(String(first4)) ?? "", radix: 0)
        } catch {
            return nil
        }
    }
}
