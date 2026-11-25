import SwiftUI
import SampleTVDomain
import SampleTVUI

public struct ProfileView: View {
    @State private var isSignOutConfirmationPresented = false
    @ObservedObject private var viewModel: ProfileViewModel
    
    public init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Account Header
                accountHeader
                
                // Profile Switcher
                profileSwitcher
                
                // Preferences Section
                preferencesSection
                
                // Watch History Section
                watchHistorySection
                
                // Sign Out Button
                signOutButton
            }
            .padding(.horizontal)
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Sign Out", isPresented: $isSignOutConfirmationPresented) {
            Button("Sign Out") { }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private var accountHeader: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.currentProfile?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Account")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 10)
    }
    
    private var profileSwitcher: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Profile")
                    .font(.headline)
                
                ForEach(viewModel.profiles) { profile in
                    HStack {
                        Text(profile.name)
                            .foregroundColor(profile.isMain ? .primary : .secondary)
                        
                        Spacer()
                        
                        if profile.isMain {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .buttonStyle(.card)
                    .onSelect {
                        Task {
                            await viewModel.switchToProfile(profile.id)
                        }
                    }
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Preferences")
                    .font(.headline)
                
                HStack {
                    Text("Default media type")
                    
                    Spacer()
                    
                    Menu {
                        ForEach(MediaKind.allCases, id: \.self) { kind in
                            Button(kind.rawValue) {
                                var newPrefs = viewModel.preferences
                                newPrefs.defaultKind = kind
                                Task {
                                    await viewModel.updatePreferences(newPrefs)
                                }
                            }
                        }
                    } label: {
                        Text(viewModel.preferences.defaultKind.rawValue)
                            .foregroundColor(.secondary)
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
            .padding(.vertical, 8)
        }
    }
    
    private var watchHistorySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("Watch History")
                    .font(.headline)
                
                HStack {
                    Text("\(viewModel.watchHistoryCount) items")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Clear Watch History") {
                        Task {
                            await viewModel.clearWatchHistory()
                        }
                    }
                    .foregroundColor(.red)
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private var signOutButton: some View {
        HStack {
            Spacer()
            
            Button("Sign Out") {
                isSignOutConfirmationPresented = true
            }
            .buttonStyle(.card)
            .foregroundColor(.red)
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel(
        getCurrentProfile: GetCurrentUserProfile(repository: MockProfileRepository()),
        getPreferences: GetUserPreferences(repository: MockProfileRepository()),
        updatePreferences: UpdateUserPreferences(repository: MockProfileRepository()),
        switchProfile: SwitchProfile(repository: MockProfileRepository()),
        progressStore: UserDefaultsPlaybackProgressStore()
    ))
}

// Temporary mock repository for preview - this will be replaced with actual implementation
private class MockProfileRepository: ProfileRepository {
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
    
    func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {
        // Mock implementation
    }
    
    func switchProfile(to profileID: String) async throws {
        // Mock implementation
    }
}