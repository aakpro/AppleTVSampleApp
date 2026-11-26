import SampleTVPlayer
import SwiftUI

struct PlayerScreen: View {
    @State private var viewModel: PlayerScreenViewModel

    init(viewModel: PlayerScreenViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isReady {
                PlayerView(
                    url: viewModel.url,
                    title: viewModel.title,
                    subtitle: viewModel.subtitle,
                    initialPosition: viewModel.initialPosition
                ) { position, duration in
                    Task {
                        await viewModel.saveProgress(position: position, duration: duration)
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
