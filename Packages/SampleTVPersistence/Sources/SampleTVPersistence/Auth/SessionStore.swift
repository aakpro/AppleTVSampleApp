import Foundation

/// Abstraction over secure session storage so tests can stub Keychain access.
public protocol SessionStore: Sendable {
    func load() -> Data?
    func save(_ data: Data)
    func clear()
}
