import SampleTVDomain
import SwiftUI

struct PreferencesSection: View {
    let viewModel: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.headline)

            HStack {
                Text("Default media type")

                Spacer()

                Menu {
                    ForEach(MediaKind.allCases, id: \.self) { kind in
                        Button(kind.rawValue.capitalized) {
                            var newPrefs = viewModel.preferences
                            newPrefs.defaultKind = kind
                            Task {
                                await viewModel.updatePreferences(newPrefs)
                            }
                        }
                    }
                } label: {
                    Text(viewModel.preferences.defaultKind.rawValue.capitalized)
                        .foregroundStyle(.secondary)
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
    }
}
