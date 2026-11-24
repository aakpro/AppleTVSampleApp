import AVKit
import Combine
import SwiftUI

/// Thin wrapper over the system player. tvOS already provides transport controls, scrubbing,
/// audio/subtitle pickers and Siri Remote handling; don't rebuild them.
public struct PlayerView: View {
    private let url: URL
    private let initialPosition: TimeInterval?
    private let onProgress: ((TimeInterval, TimeInterval) -> Void)?
    @State private var player: AVPlayer
    @State private var failure: String?
    @State private var progressTimer: Task<Void, Never>?

    public init(url: URL, initialPosition: TimeInterval? = nil, onProgress: ((TimeInterval, TimeInterval) -> Void)? = nil) {
        self.url = url
        self.initialPosition = initialPosition
        self.onProgress = onProgress
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
            .task { 
                await observeStatus() 
                // Set initial position after player is ready
                if let initialPosition {
                    player.seek(to: CMTime(seconds: initialPosition, preferredTimescale: 1000))
                }
                scheduleProgressUpdates()
            }
            .onAppear { 
                player.play() 
            }
            .onDisappear { 
                player.pause()
                progressTimer?.cancel()
                // Notify that the player disappeared so it can save final state or clear
                onProgress?(player.currentTime().seconds, player.currentItem?.duration.seconds ?? 0)
            }
    }

    /// `AVPlayerItem.status` flips to `.failed` for bad URLs, DRM and network errors.
    private func observeStatus() async {
        guard let item = player.currentItem else { return }
        for await status in item.publisher(for: \.status).values where status == .failed {
            failure = item.error?.localizedDescription ?? "Unknown error"
            return
        }
    }
    
    /// Periodically report progress to the delegate
    private func scheduleProgressUpdates() {
        progressTimer = Task { [weak player] in
            guard let player else { return }
            
            // Report progress every 5 seconds
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 5_000_000_000) 
                
                if let currentItem = player.currentItem {
                    let position = currentItem.currentTime().seconds
                    let duration = currentItem.duration.seconds
                    onProgress?(position, duration)
                }
            }
        }
    }
}