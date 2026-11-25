import AVKit
import Combine
import SwiftUI

/// Thin wrapper over the system player. tvOS already provides transport controls, scrubbing,
/// audio/subtitle pickers and Siri Remote handling; don't rebuild them.
public struct PlayerView: View {
    private let url: URL
    private let title: String?
    private let subtitle: String?
    private let initialPosition: TimeInterval?
    private let onProgress: (@MainActor @Sendable (TimeInterval, TimeInterval) -> Void)?
    @State private var player: AVPlayer
    @State private var failure: String?

    public init(
        url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        initialPosition: TimeInterval? = nil,
        onProgress: (@MainActor @Sendable (TimeInterval, TimeInterval) -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.initialPosition = initialPosition
        self.onProgress = onProgress
        let player = AVPlayer(url: url)
        _player = State(initialValue: player)
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
            .task {
                async let statusTask: Void = observeStatus()
                async let progressTask: Void = runProgressLoop()
                _ = await (statusTask, progressTask)
            }
            .onAppear {
                player.play()
            }
            .onDisappear {
                player.pause()
                reportCurrentProgress()
            }
    }

    /// Observes `AVPlayerItem.status` for readiness (initial seek) and failures.
    private func observeStatus() async {
        guard let item = player.currentItem else { return }
        var didSeek = false
        for await status in item.publisher(for: \.status).values {
            switch status {
            case .readyToPlay:
                if !didSeek, let initialPosition, initialPosition > 0 {
                    didSeek = true
                    await player.seek(to: CMTime(seconds: initialPosition, preferredTimescale: 1000))
                }
            case .failed:
                failure = item.error?.localizedDescription ?? "Unknown error"
                return
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }

    /// Periodically reports playback progress every 5 seconds until the view disappears.
    private func runProgressLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }
            reportCurrentProgress()
        }
    }

    private func reportCurrentProgress() {
        guard let item = player.currentItem else { return }
        let position = item.currentTime().seconds
        let duration = item.duration.seconds
        guard position.isFinite, position >= 0, duration.isFinite, duration > 0 else { return }
        onProgress?(position, duration)
    }
}
