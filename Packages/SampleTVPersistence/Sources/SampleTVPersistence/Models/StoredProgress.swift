import Foundation
import SampleTVDomain
import SwiftData

@Model
public final class StoredProgress {
    @Attribute(.unique) public var id: String
    public var profileID: String
    public var mediaKindRaw: String
    public var mediaIDValue: Int
    public var position: Double
    public var duration: Double
    public var updatedAt: Date
    public var seasonNumber: Int?
    public var episodeNumber: Int?

    public init(
        profileID: String,
        mediaKindRaw: String,
        mediaIDValue: Int,
        position: Double,
        duration: Double,
        updatedAt: Date,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil
    ) {
        self.id = Self.compositeID(profileID: profileID, kindRaw: mediaKindRaw, value: mediaIDValue)
        self.profileID = profileID
        self.mediaKindRaw = mediaKindRaw
        self.mediaIDValue = mediaIDValue
        self.position = position
        self.duration = duration
        self.updatedAt = updatedAt
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
    }

    public convenience init(progress: PlaybackProgress) {
        self.init(
            profileID: progress.profileID,
            mediaKindRaw: progress.mediaID.kind.rawValue,
            mediaIDValue: progress.mediaID.value,
            position: progress.position,
            duration: progress.duration,
            updatedAt: progress.updatedAt,
            seasonNumber: progress.seasonNumber,
            episodeNumber: progress.episodeNumber
        )
    }

    public var playbackProgress: PlaybackProgress {
        let kind = MediaKind(rawValue: mediaKindRaw) ?? .movie
        return PlaybackProgress(
            mediaID: MediaID(kind: kind, value: mediaIDValue),
            position: position,
            duration: duration,
            updatedAt: updatedAt,
            profileID: profileID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber
        )
    }

    static func compositeID(profileID: String, kindRaw: String, value: Int) -> String {
        "\(profileID)-\(kindRaw)-\(value)"
    }
}
