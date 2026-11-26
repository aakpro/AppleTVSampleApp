import AVFoundation
import SwiftUI

/// Non-interactive muted backdrop video preview for movie/show detail headers.
struct MutedTrailerBackdropView: UIViewRepresentable {
    let url: URL
    let isPaused: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.isUserInteractionEnabled = false
        context.coordinator.configure(url: url, on: view, isPaused: isPaused)
        return view
    }

    func updateUIView(_ uiView: PlayerContainerView, context: Context) {
        context.coordinator.configure(url: url, on: uiView, isPaused: isPaused)
    }

    static func dismantleUIView(_ uiView: PlayerContainerView, coordinator: Coordinator) {
        coordinator.stop(on: uiView)
    }

    @MainActor
    final class Coordinator {
        private var currentURL: URL?
        private var player: AVPlayer?
        private var loopObserverTask: Task<Void, Never>?

        func configure(url: URL, on view: PlayerContainerView, isPaused: Bool) {
            if currentURL != url || player == nil {
                stop(on: view)
                currentURL = url
                let item = AVPlayerItem(url: url)
                let newPlayer = AVPlayer(playerItem: item)
                newPlayer.isMuted = true
                newPlayer.actionAtItemEnd = .none
                player = newPlayer
                view.playerLayer.player = newPlayer

                loopObserverTask = Task { [weak newPlayer, weak item] in
                    for await _ in NotificationCenter.default.notifications(
                        named: .AVPlayerItemDidPlayToEndTime,
                        object: item
                    ) {
                        guard !Task.isCancelled else { break }
                        await newPlayer?.seek(to: .zero)
                        newPlayer?.play()
                    }
                }
            }

            if isPaused {
                player?.pause()
            } else {
                player?.play()
            }
        }

        func stop(on view: PlayerContainerView) {
            loopObserverTask?.cancel()
            loopObserverTask = nil
            player?.pause()
            player = nil
            view.playerLayer.player = nil
            currentURL = nil
        }
    }

    final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer {
            // Safe because layerClass is overridden to AVPlayerLayer.
            layer as? AVPlayerLayer ?? AVPlayerLayer()
        }

        override func didMoveToSuperview() {
            super.didMoveToSuperview()
            playerLayer.videoGravity = .resizeAspectFill
        }
    }
}
