import AVKit
import Foundation
import Observation

@MainActor
@Observable
public final class PlayerViewModel {
    public let url: URL
    public let title: String?
    public let subtitle: String?
    public let initialPosition: TimeInterval?
    public let player: AVPlayer

    public private(set) var failure: String?

    private let progressInterval: Duration
    private let onProgress: (@MainActor @Sendable (TimeInterval, TimeInterval) -> Void)?
    private var didSeek = false
    private var statusObservation: NSKeyValueObservation?
    private var failedObserver: (any NSObjectProtocol)?

    public init(
        url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        initialPosition: TimeInterval? = nil,
        progressInterval: Duration = .seconds(5),
        onProgress: (@MainActor @Sendable (TimeInterval, TimeInterval) -> Void)? = nil
    ) {
        self.url = url
        self.title = title
        self.subtitle = subtitle
        self.initialPosition = initialPosition
        self.progressInterval = progressInterval
        self.onProgress = onProgress

        let item = AVPlayerItem(url: url)
        item.externalMetadata = Self.buildMetadata(title: title, subtitle: subtitle)
        self.player = AVPlayer(playerItem: item)
    }

    public func play() {
        player.play()
    }

    public func pause() {
        player.pause()
        reportCurrentProgress()
    }

    public func startObserving() async {
        async let statusTask: Void = observeItemStatus()
        async let failureTask: Void = observeFailedToPlayToEnd()
        async let progressTask: Void = runProgressLoop()
        _ = await (statusTask, failureTask, progressTask)
    }

    public func handleStatus(_ status: AVPlayerItem.Status, errorDescription: String? = nil) async {
        switch status {
        case .readyToPlay:
            failure = nil
            if !didSeek, let initialPosition, initialPosition > 0 {
                didSeek = true
                await player.seek(to: CMTime(seconds: initialPosition, preferredTimescale: 1000))
            }
        case .failed:
            failure = errorDescription ?? player.currentItem?.error?.localizedDescription ?? "Unknown error"
        case .unknown:
            break
        @unknown default:
            break
        }
    }

    public func reportCurrentProgress() {
        guard let item = player.currentItem else { return }
        let position = item.currentTime().seconds
        let duration = item.duration.seconds
        guard position.isFinite, position >= 0, duration.isFinite, duration > 0 else { return }
        onProgress?(position, duration)
    }

    public static func buildMetadata(title: String?, subtitle: String?) -> [AVMetadataItem] {
        var items: [AVMetadataItem] = []
        if let title {
            let item = AVMutableMetadataItem()
            item.identifier = .commonIdentifierTitle
            item.value = title as NSString
            item.extendedLanguageTag = "und"
            items.append(item)
        }
        if let subtitle {
            let item = AVMutableMetadataItem()
            item.identifier = .commonIdentifierDescription
            item.value = subtitle as NSString
            item.extendedLanguageTag = "und"
            items.append(item)
        }
        return items
    }

    private func observeItemStatus() async {
        guard let item = player.currentItem else { return }
        let stream = AsyncStream<Int> { continuation in
            let observation = item.observe(\.status, options: [.initial, .new]) { observedItem, _ in
                continuation.yield(observedItem.status.rawValue)
            }
            MainActor.assumeIsolated {
                self.statusObservation = observation
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.statusObservation?.invalidate()
                    self?.statusObservation = nil
                }
            }
        }

        for await rawStatus in stream {
            guard !Task.isCancelled else { break }
            if let status = AVPlayerItem.Status(rawValue: rawStatus) {
                await handleStatus(status)
                if status == .failed {
                    break
                }
            }
        }
        statusObservation?.invalidate()
        statusObservation = nil
    }

    private func observeFailedToPlayToEnd() async {
        guard let item = player.currentItem else { return }
        let stream = AsyncStream<String?> { continuation in
            let token = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemFailedToPlayToEndTime,
                object: item,
                queue: .main
            ) { notification in
                let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
                continuation.yield(error?.localizedDescription)
            }
            MainActor.assumeIsolated {
                self.failedObserver = token
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    if let observer = self?.failedObserver {
                        NotificationCenter.default.removeObserver(observer)
                        self?.failedObserver = nil
                    }
                }
            }
        }

        for await errorMessage in stream {
            guard !Task.isCancelled else { break }
            await handleStatus(.failed, errorDescription: errorMessage)
        }
        if let observer = failedObserver {
            NotificationCenter.default.removeObserver(observer)
            failedObserver = nil
        }
    }

    private func runProgressLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(for: progressInterval)
            guard !Task.isCancelled else { return }
            reportCurrentProgress()
        }
    }
}
