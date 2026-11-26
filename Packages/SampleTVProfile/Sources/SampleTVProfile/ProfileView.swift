import SampleTVDomain
import SwiftUI

public struct ProfileView: View {
    @State private var isSignOutConfirmationPresented = false
    @State private var viewModel: ProfileViewModel
    private let onSelectItem: ((MediaItem) -> Void)?

    public init(viewModel: ProfileViewModel, onSelectItem: ((MediaItem) -> Void)? = nil) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectItem = onSelectItem
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                AccountHeaderSection(viewModel: viewModel)
                ProfileSwitcherSection(viewModel: viewModel)
                PreferencesSection(viewModel: viewModel)
                WatchHistorySection(viewModel: viewModel)
                WatchlistSection(viewModel: viewModel, onSelectItem: onSelectItem)
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

#if DEBUG
#Preview {
    ProfileView(viewModel: .preview)
}
#endif
