import Foundation
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
