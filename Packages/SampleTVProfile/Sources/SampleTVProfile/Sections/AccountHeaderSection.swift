import SampleTVDomain
import SwiftUI

struct AccountHeaderSection: View {
    let viewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.account?.displayName ?? viewModel.currentProfile?.name ?? "User")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text(viewModel.account?.email ?? "Account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
