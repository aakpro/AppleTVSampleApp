import Foundation
import SampleTVDomain

public actor MockAuthRepository: AuthRepository {
    private let userDefaults: UserDefaults
    
    public init(suiteName: String = "com.sampletv.auth") {
        self.userDefaults = UserDefaults(suiteName: suiteName)!
    }
    
    public func currentAccount() async -> UserAccount? {
        guard let data = userDefaults.data(forKey: "currentAccount") else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(UserAccount.self, from: data)
        } catch {
            // If decoding fails, clear the stored account and return nil
            userDefaults.removeObject(forKey: "currentAccount")
            return nil
        }
    }
    
    public func signIn(email: String, password: String) async throws -> UserAccount {
        // Trim whitespace
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate inputs
        if trimmedEmail.isEmpty || trimmedPassword.isEmpty {
            throw AuthError.emptyFields
        }
        
        if !trimmedEmail.contains("@") || !trimmedEmail.contains(".") {
            throw AuthError.invalidCredentials
        }
        
        if trimmedPassword.count < 4 {
            throw AuthError.invalidCredentials
        }
        
        // Create a user account (in a real app this would be fetched from a server)
        let account = UserAccount(
            id: UUID().uuidString,
            email: trimmedEmail,
            displayName: trimmedEmail.components(separatedBy: "@").first ?? "User",
            avatarSystemName: "person.circle",
            isDemo: false,
            createdAt: Date()
        )
        
        // Persist the account
        let data = try JSONEncoder().encode(account)
        userDefaults.set(data, forKey: "currentAccount")
        
        return account
    }
    
    public func signInDemo() async throws -> UserAccount {
        // Create a demo account
        let account = UserAccount(
            id: "demo_user",
            email: "demo@sampletv.app",
            displayName: "Alex Mercer",
            avatarSystemName: "person.circle",
            isDemo: true,
            createdAt: Date()
        )
        
        // Persist the account
        let data = try JSONEncoder().encode(account)
        userDefaults.set(data, forKey: "currentAccount")
        
        return account
    }
    
    public func signOut() async {
        userDefaults.removeObject(forKey: "currentAccount")
    }
}