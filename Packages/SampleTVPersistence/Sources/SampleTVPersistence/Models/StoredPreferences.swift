import Foundation
import SwiftData

@Model
public final class StoredPreferences {
    @Attribute(.unique) public var profileID: String
    public var defaultKindRaw: String
    public var autoplayTrailers: Bool

    public init(profileID: String, defaultKindRaw: String, autoplayTrailers: Bool) {
        self.profileID = profileID
        self.defaultKindRaw = defaultKindRaw
        self.autoplayTrailers = autoplayTrailers
    }
}
