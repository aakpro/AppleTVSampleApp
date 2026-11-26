import SampleTVDiscovery
import SampleTVDomain
import SwiftUI

struct DetailsScreen: View {
    let container: AppContainer
    let item: MediaItem
    let profileID: String
    let onSelectRecommendation: (MediaItem) -> Void
    @State private var viewModel: DetailsScreenViewModel
    @State private var detailsViewModel: DetailsViewModel

    init(
        container: AppContainer,
        item: MediaItem,
        profileID: String,
        onSelectRecommendation: @escaping (MediaItem) -> Void
    ) {
        self.container = container
        self.item = item
        self.profileID = profileID
        self.onSelectRecommendation = onSelectRecommendation
        _viewModel = State(initialValue: container.makeDetailsScreenViewModel(profileID: profileID))
        _detailsViewModel = State(initialValue: container.makeDetailsViewModel(for: item, profileID: profileID))
    }

    var body: some View {
        DetailsView(
            viewModel: detailsViewModel,
            isPreviewPaused: viewModel.playbackSelection != nil,
            onPlay: { selected in
                Task {
                    await viewModel.startPlayback(
                        for: selected,
                        episode: selected.id.kind == .tv ? detailsViewModel.selectedEpisode : nil,
                        kind: .feature
                    )
                }
            },
            onPlayTrailer: { selected in
                Task {
                    await viewModel.startPlayback(
                        for: selected,
                        kind: .trailer,
                        trailerTitle: detailsViewModel.preferredTrailerTitle
                    )
                }
            },
            onSelectRecommendation: onSelectRecommendation,
            onPlayEpisode: { selected, episode in
                Task {
                    await viewModel.startPlayback(for: selected, episode: episode, kind: .feature)
                }
            }
        )
        .fullScreenCover(item: $viewModel.playbackSelection) { selection in
            PlayerScreen(viewModel: container.makePlayerScreenViewModel(selection: selection))
        }
    }
}
