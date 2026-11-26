import Foundation
import SwiftData

@Model
public final class StoredProfile {
    @Attribute(.unique) public var id: String
    public var name: String
    public var isMain: Bool
    public var isActive: Bool

    public init(id: String, name: String, isMain: Bool, isActive: Bool) {
        self.id = id
        self.name = name
        self.isMain = isMain
        self.isActive = isActive
    }
}
