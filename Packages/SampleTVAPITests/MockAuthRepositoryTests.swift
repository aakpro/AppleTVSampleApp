import Testing
import SampleTVDomain
import SampleTVAPI

@Suite("MockAuthRepository Tests")
struct MockAuthRepositoryTests {
    
    @Test("SignIn with empty fields throws AuthError.emptyFields")
    func signInEmptyFields() async throws {
        let repository = MockAuthRepository(suiteName: "test_auth_empty_fields")
        
        do {
            _ = try await repository.signIn(email: "", password: "")
            #expect(false, "Expected AuthError.emptyFields to be thrown")
        } catch {
            if let authError = error as? AuthError {
                #expect(authError == .emptyFields)
            } else {
                #expect(false, "Expected AuthError.emptyFields to be thrown")
            }
        }
    }
    
    @Test("SignIn with invalid email format throws AuthError.invalidCredentials")
    func signInInvalidEmail() async throws {
        let repository = MockAuthRepository(suiteName: "test_auth_invalid_email")
        
        do {
            _ = try await repository.signIn(email: "invalid-email", password: "password")
            #expect(false, "Expected AuthError.invalidCredentials to be thrown")
        } catch {
            if let authError = error as? AuthError {
                #expect(authError == .invalidCredentials)
            } else {
                #expect(false, "Expected AuthError.invalidCredentials to be thrown")
            }
        }
    }
    
    @Test("SignIn with password less than 4 characters throws AuthError.invalidCredentials")
    func signInShortPassword() async throws {
        let repository = MockAuthRepository(suiteName: "test_auth_short_password")
        
        do {
            _ = try await repository.signIn(email: "user@example.com", password: "123")
            #expect(false, "Expected AuthError.invalidCredentials to be thrown")
        } catch {
            if let authError = error as? AuthError {
                #expect(authError == .invalidCredentials)
            } else {
                #expect(false, "Expected AuthError.invalidCredentials to be thrown")
            }
        }
    }
    
    @Test("SignIn with valid credentials works correctly")
    func signInValidCredentials() async throws {
        let repository = MockAuthRepository(suiteName: "test_auth_valid")
        
        let account = try await repository.signIn(email: "user@example.com", password: "password123")
        
        #expect(account.email == "user@example.com")
        #expect(account.displayName == "user")
        #expect(account.isDemo == false)
    }
    
    @Test("SignInDemo works correctly")
    func signInDemo() async throws {
        let repository = MockAuthRepository(suiteName: "test_auth_demo")
        
        let account = try await repository.signInDemo()
        
        #expect(account.email == "demo@sampletv.app")
        #expect(account.displayName == "Alex Mercer")
        #expect(account.isDemo == true)
    }
    
    @Test("SignOut works correctly")
    func signOut() async throws {
        let repository = MockAuthRepository(suiteName: "test_auth_signout")
        
        // First sign in to set up an account
        _ = try await repository.signIn(email: "user@example.com", password: "password123")
        
        // Sign out
        await repository.signOut()
        
        // Verify account is cleared
        let currentAccount = await repository.currentAccount()
        #expect(currentAccount == nil)
    }
    
    @Test("Persistence works correctly - account persists across calls")
    func persistence() async throws {
        let suiteName = "test_auth_persistence"
        let repository1 = MockAuthRepository(suiteName: suiteName)
        let repository2 = MockAuthRepository(suiteName: suiteName)
        
        // Sign in with first instance
        let account = try await repository1.signIn(email: "user@example.com", password: "password123")
        
        // Verify account is persisted and retrievable by second instance
        let retrievedAccount = await repository2.currentAccount()
        #expect(retrievedAccount?.email == account.email)
    }
}