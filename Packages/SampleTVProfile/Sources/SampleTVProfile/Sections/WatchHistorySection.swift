import SwiftUI

struct WatchHistorySection: View {
    let viewModel: ProfileViewModel

    var body: some View {
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
}
