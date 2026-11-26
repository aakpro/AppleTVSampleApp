import Foundation
import SampleTVDomain
import SwiftData

@Model
public final class StoredWatchlistItem {
    @Attribute(.unique) public var id: String
    public var profileID: String
    public var mediaKindRaw: String
    public var mediaIDValue: Int
    public var title: String
    public var overview: String
    public var releaseYear: Int?
    public var genreIDsData: Data?
    public var rating: Double?
    public var posterPath: String?
    public var backdropPath: String?
    public var addedAt: Date

    public init(
        id: String,
        profileID: String,
        mediaKindRaw: String,
        mediaIDValue: Int,
        title: String,
        overview: String,
        releaseYear: Int?,
        genreIDsData: Data?,
        rating: Double?,
        posterPath: String?,
        backdropPath: String?,
        addedAt: Date
    ) {
        self.id = id
        self.profileID = profileID
        self.mediaKindRaw = mediaKindRaw
        self.mediaIDValue = mediaIDValue
        self.title = title
        self.overview = overview
        self.releaseYear = releaseYear
        self.genreIDsData = genreIDsData
        self.rating = rating
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.addedAt = addedAt
    }

    public convenience init(
        profileID: String,
        mediaItem: MediaItem,
        addedAt: Date = Date()
    ) {
        let id = "\(profileID)-\(mediaItem.id.kind.rawValue)-\(mediaItem.id.value)"
        self.init(
            id: id,
            profileID: profileID,
            mediaKindRaw: mediaItem.id.kind.rawValue,
            mediaIDValue: mediaItem.id.value,
            title: mediaItem.title,
            overview: mediaItem.overview,
            releaseYear: mediaItem.releaseYear,
            genreIDsData: try? JSONEncoder().encode(mediaItem.genreIDs),
            rating: mediaItem.rating,
            posterPath: mediaItem.posterPath,
            backdropPath: mediaItem.backdropPath,
            addedAt: addedAt
        )
    }

    public var mediaItem: MediaItem {
        let kind = MediaKind(rawValue: mediaKindRaw) ?? .movie
        let genreIDs: [Int]
        if let genreIDsData,
           let decoded = try? JSONDecoder().decode([Int].self, from: genreIDsData) {
            genreIDs = decoded
        } else {
            genreIDs = []
        }
        return MediaItem(
            id: MediaID(kind: kind, value: mediaIDValue),
            title: title,
            overview: overview,
            releaseYear: releaseYear,
            genreIDs: genreIDs,
            rating: rating,
            posterPath: posterPath,
            backdropPath: backdropPath
        )
    }
}
