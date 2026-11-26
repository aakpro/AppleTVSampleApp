import AVKit
import SwiftUI

/// Thin wrapper over the system player. tvOS already provides transport controls, scrubbing,
/// audio/subtitle pickers and Siri Remote handling; don't rebuild them.
public struct PlayerView: View {
    @State private var viewModel: PlayerViewModel
    @Environment(\.dismiss) private var dismiss

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
        ZStack {
            if let failure = viewModel.failure {
                failureOverlay(message: failure)
            } else {
                VideoPlayer(player: viewModel.player)
                    .ignoresSafeArea()
            }
        }
        .task(id: viewModel.attemptID) { await viewModel.startObserving() }
        .onAppear { viewModel.play() }
        .onDisappear { viewModel.pause() }
    }

    private func failureOverlay(message: String) -> some View {
        ZStack {
            Color.black.opacity(0.96).ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 56))
                    .foregroundStyle(.red)

                Text("Playback Failed")
                    .font(.title2)
                    .fontWeight(.bold)

                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 640)

                HStack(spacing: 24) {
                    Button {
                        viewModel.retry()
                    } label: {
                        Label("Try Again", systemImage: "arrow.clockwise")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(60)
        }
    }
}
