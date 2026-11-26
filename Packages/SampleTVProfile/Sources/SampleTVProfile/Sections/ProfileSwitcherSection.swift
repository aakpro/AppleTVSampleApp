import SampleTVDomain
import SampleTVUI
import SwiftUI

struct ProfileSwitcherSection: View {
    let viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Profiles")
                .font(SampleTVTheme.Typography.sectionTitle)

            HStack(spacing: 24) {
                ForEach(viewModel.profiles) { profile in
                    let isSelected = profile.id == viewModel.currentProfile?.id
                    Button {
                        Task {
                            await viewModel.switchToProfile(profile.id)
                        }
                    } label: {
                        HStack(spacing: 14) {
                            let symbolName = profile.isMain
                                ? "person.crop.circle.fill"
                                : "figure.and.child.holdinghands"
                            Image(systemName: symbolName)
                                .font(.title2)
                                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(profile.isMain ? "Primary" : "Profile")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(.card)
                    .accessibilityLabel("\(profile.name), \(isSelected ? "selected profile" : "profile")")
                    .accessibilityIdentifier("profile.switcher.\(profile.id)")
                }
            }
        }
    }
}
