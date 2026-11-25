import Foundation
import Security

/// Abstraction over secure session storage so tests can stub Keychain access.
public protocol SessionStore: Sendable {
    func load() -> Data?
    func save(_ data: Data)
    func clear()
}

/// Keychain-backed `SessionStore` for persisting authenticated session payloads on tvOS.
public struct KeychainSessionStore: SessionStore {
    private let service: String
    private let account: String

    public init(service: String = "com.sampletv.auth", account: String = "currentSession") {
        self.service = service
        self.account = account
    }

    public func load() -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    public func save(_ data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }

    public func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

/// `UserDefaults`-backed `SessionStore` for isolated unit tests.
public struct UserDefaultsSessionStore: SessionStore {
    private let suiteName: String
    private let key: String

    public init(suiteName: String = "com.sampletv.auth", key: String = "currentAccount") {
        self.suiteName = suiteName
        self.key = key
    }

    public func load() -> Data? {
        (UserDefaults(suiteName: suiteName) ?? .standard).data(forKey: key)
    }

    public func save(_ data: Data) {
        (UserDefaults(suiteName: suiteName) ?? .standard).set(data, forKey: key)
    }

    public func clear() {
        (UserDefaults(suiteName: suiteName) ?? .standard).removeObject(forKey: key)
    }
}
