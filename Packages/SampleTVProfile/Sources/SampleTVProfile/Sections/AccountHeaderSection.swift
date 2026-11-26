import SampleTVDomain
import SwiftUI

struct AccountHeaderSection: View {
    let viewModel: ProfileViewModel

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: viewModel.account?.avatarSystemName ?? "person.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    Text(viewModel.account?.displayName ?? viewModel.currentProfile?.name ?? "User")
                        .font(.title2.weight(.semibold))

                    if viewModel.account?.isDemo == true {
                        Text("Demo")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.14), in: Capsule())
                    }
                }

                Text(viewModel.account?.email ?? "Signed-in account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
    }
}
