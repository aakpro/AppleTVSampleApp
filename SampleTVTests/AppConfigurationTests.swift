import Testing
@testable import SampleTV

struct AppConfigurationTests {
    @Test(arguments: ["", "paste_your_token_here"])
    func missingOrPlaceholderTokenIsRejected(token: String) {
        #expect(!AppConfiguration(tmdbToken: token).hasToken)
    }

    @Test func realLookingTokenIsAccepted() {
        #expect(AppConfiguration(tmdbToken: "eyJhbGciOi").hasToken)
    }
}
