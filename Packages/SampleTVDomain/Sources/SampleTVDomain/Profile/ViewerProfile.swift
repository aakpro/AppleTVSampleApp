import Foundation

public struct ViewerProfile: Identifiable, Codable, Hashable, Sendable {
    public static let defaultID = "main"

    public let id: String
    public let name: String
    public let isMain: Bool

    public init(id: String, name: String, isMain: Bool) {
        self.id = id
        self.name = name
        self.isMain = isMain
    }
}
