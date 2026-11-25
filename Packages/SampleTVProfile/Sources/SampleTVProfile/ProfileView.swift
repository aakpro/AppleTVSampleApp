import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct ProfileView: View {
    @State private var isSignOutConfirmationPresented = false
    let viewModel: ProfileViewModel
    private let onSelectItem: ((MediaItem) -> Void)?

    public init(viewModel: ProfileViewModel, onSelectItem: ((MediaItem) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSelectItem = onSelectItem
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                accountHeader
                profileSwitcher
                preferencesSection
                watchHistorySection
                watchlistSection
                signOutButton
            }
            .padding(48)
        }
        .navigationTitle("Profile")
        .task {
            await viewModel.load()
        }
        .confirmationDialog("Sign Out", isPresented: $isSignOutConfirmationPresented) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await viewModel.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }

    private var accountHeader: some View {
        HStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentProfile?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var profileSwitcher: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profiles")
                .font(.headline)

            HStack(spacing: 20) {
                ForEach(viewModel.profiles) { profile in
                    let isSelected = profile.id == viewModel.currentProfile?.id
                    Button {
                        Task {
                            await viewModel.switchToProfile(profile.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Text(profile.name)
                                .foregroundStyle(isSelected ? .primary : .secondary)

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.card)
                }
            }
        }
    }

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)

            HStack {
                Text("Default media type")

                Spacer()

                Menu {
                    ForEach(MediaKind.allCases, id: \.self) { kind in
                        Button(kind.rawValue.capitalized) {
                            var newPrefs = viewModel.preferences
                            newPrefs.defaultKind = kind
                            Task {
                                await viewModel.updatePreferences(newPrefs)
                            }
                        }
                    }
                } label: {
                    Text(viewModel.preferences.defaultKind.rawValue.capitalized)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle("Autoplay trailers", isOn: Binding<Bool>(
                get: { viewModel.preferences.autoplayTrailers },
                set: { newValue in
                    var newPrefs = viewModel.preferences
                    newPrefs.autoplayTrailers = newValue
                    Task {
                        await viewModel.updatePreferences(newPrefs)
                    }
                }
            ))
        }
    }

    private var watchHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Watch History")
                .font(.headline)

            HStack {
                Text("\(viewModel.watchHistoryCount) items")
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Clear Watch History") {
                    Task {
                        await viewModel.clearWatchHistory()
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My List")
                .font(.headline)

            if viewModel.watchlistItems.isEmpty {
                Text("No saved titles yet.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 40) {
                        ForEach(viewModel.watchlistItems) { item in
                            Button {
                                onSelectItem?(item)
                            } label: {
                                MediaCard(item: item)
                            }
                            .buttonStyle(.card)
                        }
                    }
                }
            }
        }
    }

    private var signOutButton: some View {
        HStack {
            Spacer()

            Button("Sign Out", role: .destructive) {
                isSignOutConfirmationPresented = true
            }
            .buttonStyle(.card)
        }
        .padding(.top, 12)
    }
}

#Preview {
    let profileRepo = PreviewProfileRepository()
    let authRepo = PreviewAuthRepository()
    let progressStore = PreviewProgressStore()
    let watchlistStore = PreviewWatchlistStore()
    ProfileView(viewModel: ProfileViewModel(
        getCurrentProfile: GetCurrentUserProfile(repository: profileRepo),
        getProfiles: GetProfiles(repository: profileRepo),
        getPreferences: GetUserPreferences(repository: profileRepo),
        updatePreferences: UpdateUserPreferences(repository: profileRepo),
        switchProfile: SwitchProfile(repository: profileRepo),
        signOut: SignOut(repository: authRepo),
        progressStore: progressStore,
        watchlistStore: watchlistStore,
        onSignOut: {}
    ))
}

private struct PreviewProfileRepository: ProfileRepository {
    func currentProfile() async throws -> ViewerProfile {
        ViewerProfile(id: "main", name: "Main", isMain: true)
    }

    func profiles() async throws -> [ViewerProfile] {
        [
            ViewerProfile(id: "main", name: "Main", isMain: true),
            ViewerProfile(id: "kids", name: "Kids", isMain: false),
            ViewerProfile(id: "guest", name: "Guest", isMain: false)
        ]
    }

    func preferences(for profileID: String) async throws -> UserPreferences {
        UserPreferences()
    }

    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {}

    func switchProfile(to profileID: String) async throws {}
}

private struct PreviewAuthRepository: AuthRepository {
    func signIn(email: String, password: String) async throws -> UserAccount {
        UserAccount(
            id: "preview",
            email: email,
            displayName: "Preview",
            avatarSystemName: "person.circle.fill",
            isDemo: false,
            createdAt: .now
        )
    }

    func signInDemo() async throws -> UserAccount {
        UserAccount(
            id: "demo",
            email: "demo@sampletv.app",
            displayName: "Demo",
            avatarSystemName: "person.circle.fill",
            isDemo: true,
            createdAt: .now
        )
    }

    func signOut() async {}

    func currentAccount() async -> UserAccount? { nil }
}

private struct PreviewProgressStore: PlaybackProgressStore {
    func loadProgress(for mediaID: MediaID) async throws -> PlaybackProgress? { nil }
    func saveProgress(_ progress: PlaybackProgress) async throws {}
    func clearProgress(for mediaID: MediaID) async throws {}
    func recentlyWatched(maxCount: Int) async throws -> [PlaybackProgress] { [] }
}

private struct PreviewWatchlistStore: WatchlistStore {
    func items(for profileID: String) async throws -> [MediaItem] {
        [
            MediaItem(
                id: MediaID(kind: .movie, value: 603),
                title: "The Matrix",
                releaseYear: 1999
            )
        ]
    }

    func contains(_ mediaID: MediaID, in profileID: String) async throws -> Bool { false }
    func add(_ item: MediaItem, to profileID: String) async throws {}
    func remove(_ mediaID: MediaID, from profileID: String) async throws {}
    func toggle(_ item: MediaItem, for profileID: String) async throws -> Bool { false }
}
