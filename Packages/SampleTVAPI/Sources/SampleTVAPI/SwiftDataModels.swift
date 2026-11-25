import Foundation
import SampleTVDomain
import SwiftData

@Model
final class StoredProfile {
    @Attribute(.unique) var id: String
    var name: String
    var isMain: Bool
    var isActive: Bool

    init(id: String, name: String, isMain: Bool, isActive: Bool) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.isActive = isActive
    }
}

@Model
final class StoredPreferences {
    @Attribute(.unique) var profileID: String
    var defaultKindRaw: String
    var autoplayTrailers: Bool

    init(profileID: String, defaultKindRaw: String, autoplayTrailers: Bool) {
        self.profileID = profileID
        self.defaultKindRaw = defaultKindRaw
        self.autoplayTrailers = autoplayTrailers
    }
}

@Model
final class StoredWatchlistItem {
    @Attribute(.unique) var id: String
    var profileID: String
    var mediaKindRaw: String
    var mediaIDValue: Int
    var title: String
    var overview: String
    var releaseYear: Int?
    var genreIDsData: Data?
    var rating: Double?
    var posterPath: String?
    var backdropPath: String?
    var addedAt: Date

    init(
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

    convenience init(
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

    var mediaItem: MediaItem {
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
