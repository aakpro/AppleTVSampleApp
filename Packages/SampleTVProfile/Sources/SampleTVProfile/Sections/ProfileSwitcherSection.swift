import SampleTVDomain
import SwiftUI

struct ProfileSwitcherSection: View {
    let viewModel: ProfileViewModel

    var body: some View {
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
}
