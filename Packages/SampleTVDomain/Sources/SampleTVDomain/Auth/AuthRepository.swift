import Foundation

public protocol AuthRepository: Sendable {
    func currentAccount() async -> UserAccount?
    func signIn(email: String, password: String) async throws -> UserAccount
    func signInDemo() async throws -> UserAccount
    func signOut() async
}
