import SampleTVUI
import SwiftUI

struct WatchHistorySection: View {
    let viewModel: ProfileViewModel
    @State private var isClearConfirmationPresented = false

    private var countLabel: String {
        viewModel.watchHistoryCount == 1 ? "1 item" : "\(viewModel.watchHistoryCount) items"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Watch History")
                .font(SampleTVTheme.Typography.sectionTitle)

            HStack {
                Text(countLabel)
                    .foregroundStyle(.secondary)

                Spacer()

                Button(role: .destructive) {
                    isClearConfirmationPresented = true
                } label: {
                    Text("Clear Watch History")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.watchHistoryCount == 0)
                .accessibilityIdentifier("profile.clearHistoryButton")
            }
        }
        .confirmationDialog("Clear Watch History", isPresented: $isClearConfirmationPresented) {
            Button("Clear History", role: .destructive) {
                Task {
                    await viewModel.clearWatchHistory()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Remove all watch history items for this profile?")
        }
    }
}
