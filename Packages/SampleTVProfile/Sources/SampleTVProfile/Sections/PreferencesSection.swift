import SampleTVDomain
import SampleTVUI
import SwiftUI

struct PreferencesSection: View {
    let viewModel: ProfileViewModel

    private var defaultKindBinding: Binding<MediaKind> {
        Binding(
            get: { viewModel.preferences.defaultKind },
            set: { newKind in
                var updated = viewModel.preferences
                updated.defaultKind = newKind
                Task { await viewModel.updatePreferences(updated) }
            }
        )
    }

    private var autoplayBinding: Binding<Bool> {
        Binding(
            get: { viewModel.preferences.autoplayTrailers },
            set: { newValue in
                var updated = viewModel.preferences
                updated.autoplayTrailers = newValue
                Task { await viewModel.updatePreferences(updated) }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Preferences")
                .font(SampleTVTheme.Typography.sectionTitle)

            VStack(alignment: .leading, spacing: 10) {
                Text("Default media type")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                Picker("Default media type", selection: defaultKindBinding) {
                    Text("Movies").tag(MediaKind.movie)
                    Text("TV Shows").tag(MediaKind.tv)
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("profile.defaultKindPicker")
            }

            Toggle("Autoplay trailers", isOn: autoplayBinding)
                .accessibilityIdentifier("profile.autoplayToggle")
        }
    }
}
