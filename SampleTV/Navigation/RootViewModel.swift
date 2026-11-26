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
    private let loadCurrentAccount: LoadCurrentAccount
    private let getCurrentProfile: GetCurrentUserProfile
    let hasTMDBToken: Bool

    var authenticatedAccount: UserAccount?
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
        if let account = await loadCurrentAccount() {
            authenticatedAccount = account
            await refreshActiveProfileID()
        }
    }

    func didAuthenticate(_ account: UserAccount) async {
        authenticatedAccount = account
        await refreshActiveProfileID()
    }

    func signOut() {
        selection = nil
        categoryDestination = nil
        authenticatedAccount = nil
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
