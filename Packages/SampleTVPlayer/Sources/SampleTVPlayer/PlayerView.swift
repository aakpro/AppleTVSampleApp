import AVKit
import Combine
import SwiftUI

/// Thin wrapper over the system player. tvOS already provides transport controls, scrubbing,
/// audio/subtitle pickers and Siri Remote handling; don't rebuild them.
public struct PlayerView: View {
    private let url: URL
    @State private var player: AVPlayer
    @State private var failure: String?

    public init(url: URL) {
        self.url = url
        _player = State(initialValue: AVPlayer(url: url))
    }

    public var body: some View {
        VideoPlayer(player: player)
            .ignoresSafeArea()
            .overlay {
                if let failure {
                    ContentUnavailableView(
                        "Playback Failed",
                        systemImage: "exclamationmark.triangle",
                        description: Text(failure)
                    )
                }
            }
            .task { await observeStatus() }
            .onAppear { player.play() }
            .onDisappear { player.pause() }
    }

    /// `AVPlayerItem.status` flips to `.failed` for bad URLs, DRM and network errors.
    private func observeStatus() async {
        guard let item = player.currentItem else { return }
        for await status in item.publisher(for: \.status).values where status == .failed {
            failure = item.error?.localizedDescription ?? "Unknown error"
            return
        }
    }
}