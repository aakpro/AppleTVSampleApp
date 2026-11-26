import AVKit
import SwiftUI

/// Thin wrapper over the system player. tvOS already provides transport controls, scrubbing,
/// audio/subtitle pickers and Siri Remote handling; don't rebuild them.
public struct PlayerView: View {
    @State private var viewModel: PlayerViewModel

    public init(viewModel: PlayerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public init(
        url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        initialPosition: TimeInterval? = nil,
        onProgress: (@MainActor @Sendable (TimeInterval, TimeInterval) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: PlayerViewModel(
            url: url,
            title: title,
            subtitle: subtitle,
            initialPosition: initialPosition,
            onProgress: onProgress
        ))
    }

    public var body: some View {
        VideoPlayer(player: viewModel.player)
            .ignoresSafeArea()
            .overlay {
                if let failure = viewModel.failure {
                    ContentUnavailableView(
                        "Playback Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(failure)
                    )
                }
            }
            .task { await viewModel.startObserving() }
            .onAppear { viewModel.play() }
            .onDisappear { viewModel.pause() }
    }
}
