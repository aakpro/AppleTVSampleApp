import Foundation
import Observation
import SampleTVDomain

struct CategoryDestination: Hashable {
    let kind: MediaKind
    let genre: Genre?
}

@MainActor
@Observable
final class RootViewModel {
    enum SessionState: Equatable {
        case checking
        case signedOut
        case signedIn(UserAccount)
    }

    private let loadCurrentAccount: LoadCurrentAccount
    private let getCurrentProfile: GetCurrentUserProfile
    let hasTMDBToken: Bool

    private(set) var sessionState: SessionState = .checking
    var authenticatedAccount: UserAccount? {
        guard case .signedIn(let account) = sessionState else { return nil }
        return account
    }
    var activeProfileID = ViewerProfile.defaultID
    var selection: MediaItem?
    var categoryDestination: CategoryDestination?

    init(
        loadCurrentAccount: LoadCurrentAccount,
        getCurrentProfile: GetCurrentUserProfile,
        hasTMDBToken: Bool
    ) {
        self.loadCurrentAccount = loadCurrentAccount
        self.getCurrentProfile = getCurrentProfile
        self.hasTMDBToken = hasTMDBToken
    }

    func loadSession() async {
        sessionState = .checking
        if let account = await loadCurrentAccount() {
            await refreshActiveProfileID()
            sessionState = .signedIn(account)
        } else {
            sessionState = .signedOut
        }
    }

    func didAuthenticate(_ account: UserAccount) async {
        await refreshActiveProfileID()
        sessionState = .signedIn(account)
    }

    func signOut() {
        selection = nil
        categoryDestination = nil
        sessionState = .signedOut
    }

    func refreshActiveProfileID() async {
        do {
            let profile = try await getCurrentProfile()
            activeProfileID = profile.id
        } catch {
            activeProfileID = ViewerProfile.defaultID
        }
    }

    func selectMedia(_ item: MediaItem) async {
        await refreshActiveProfileID()
        selection = item
    }

    func selectCategory(kind: MediaKind, genre: Genre?) {
        categoryDestination = CategoryDestination(kind: kind, genre: genre)
    }
}
