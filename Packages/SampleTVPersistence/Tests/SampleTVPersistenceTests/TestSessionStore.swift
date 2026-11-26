import Foundation
@testable import SampleTVPersistence

/// `UserDefaults`-backed `SessionStore` for isolated unit tests.
struct UserDefaultsSessionStore: SessionStore {
    private let suiteName: String
    private let key: String

    init(suiteName: String = "com.sampletv.auth.tests", key: String = "currentAccount") {
        self.suiteName = suiteName
        self.key = key
    }

    func load() -> Data? {
        (UserDefaults(suiteName: suiteName) ?? .standard).data(forKey: key)
    }

    func save(_ data: Data) {
        (UserDefaults(suiteName: suiteName) ?? .standard).set(data, forKey: key)
    }

    func clear() {
        (UserDefaults(suiteName: suiteName) ?? .standard).removeObject(forKey: key)
    }
}
