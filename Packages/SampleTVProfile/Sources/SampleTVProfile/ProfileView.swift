import SampleTVDomain
import SampleTVUI
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
            VStack(alignment: .leading, spacing: 36) {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Profile")
                        .font(SampleTVTheme.Typography.screenTitle)
                        .accessibilityAddTraits(.isHeader)

                    if let errorMessage = viewModel.errorMessage {
                        errorBanner(errorMessage)
                    }

                    AccountHeaderSection(viewModel: viewModel)
                    ProfileSwitcherSection(viewModel: viewModel)
                    PreferencesSection(viewModel: viewModel)
                    WatchHistorySection(viewModel: viewModel)
                    signOutButton
                }
                .frame(maxWidth: 960, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)

                WatchlistSection(viewModel: viewModel, onSelectItem: onSelectItem)
            }
            .padding(.vertical, 36)
        }
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

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text(message)
                .font(.callout)
            Spacer()
            Button("Dismiss") {
                viewModel.clearError()
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(Color.red.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var signOutButton: some View {
        HStack {
            Spacer()

            Button(role: .destructive) {
                isSignOutConfirmationPresented = true
            } label: {
                Text("Sign Out")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("profile.signOutButton")
        }
        .padding(.top, 8)
    }
}

#if DEBUG
#Preview {
    ProfileView(viewModel: .preview)
}
#endif
