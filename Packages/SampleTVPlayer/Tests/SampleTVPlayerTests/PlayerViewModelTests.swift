import AVKit
import Foundation
import Testing
@testable import SampleTVPlayer

@MainActor
struct PlayerViewModelTests {
    @Test func buildMetadataSetsTitleAndDescription() {
        let metadata = PlayerViewModel.buildMetadata(title: "Movie Title", subtitle: "Movie Description")
        #expect(metadata.count == 2)

        let titleItem = metadata.first { $0.identifier == .commonIdentifierTitle }
        let descriptionItem = metadata.first { $0.identifier == .commonIdentifierDescription }

        #expect(titleItem?.value as? String == "Movie Title")
        #expect(descriptionItem?.value as? String == "Movie Description")
    }

    @Test func initializerAttachesMetadataToCurrentItem() throws {
        let url = try #require(URL(string: "https://example.com/video.mp4"))
        let viewModel = PlayerViewModel(url: url, title: "Demo Title", subtitle: "Demo Subtitle")
        let metadata = viewModel.player.currentItem?.externalMetadata ?? []
        #expect(metadata.count == 2)
    }

    @Test func handleStatusFailedSetsFailureDescriptionAndReadyToPlayClearsIt() async throws {
        let url = try #require(URL(string: "https://example.com/video.mp4"))
        let viewModel = PlayerViewModel(url: url)

        await viewModel.handleStatus(.failed, errorDescription: "Stream error")
        #expect(viewModel.failure == "Stream error")

        await viewModel.handleStatus(.readyToPlay)
        #expect(viewModel.failure == nil)
    }

    @Test func reportCurrentProgressSkipsWhenDurationIsIndefinite() throws {
        let url = try #require(URL(string: "https://example.com/video.mp4"))
        var reported = false
        let viewModel = PlayerViewModel(url: url) { _, _ in
            reported = true
        }

        viewModel.reportCurrentProgress()
        #expect(reported == false)
    }

    @Test func retryClearsFailureIncrementsAttemptIDAndReplacesCurrentItem() async throws {
        let url = try #require(URL(string: "https://example.com/video.mp4"))
        let viewModel = PlayerViewModel(url: url)

        await viewModel.handleStatus(.failed, errorDescription: "Stream error")
        #expect(viewModel.failure == "Stream error")
        let initialAttemptID = viewModel.attemptID

        viewModel.retry()
        #expect(viewModel.failure == nil)
        #expect(viewModel.attemptID == initialAttemptID + 1)

        let newItem = viewModel.player.currentItem
        #expect(newItem != nil)
    }

    @Test func playPauseUnknownStatusAndCancellationSafeObservation() async throws {
        let url = try #require(URL(string: "https://example.com/video.mp4"))
        let viewModel = PlayerViewModel(url: url, initialPosition: 30)

        viewModel.play()
        viewModel.pause()
        await viewModel.handleStatus(.unknown)
        #expect(viewModel.failure == nil)

        await viewModel.handleStatus(.failed, errorDescription: nil)
        #expect(viewModel.failure != nil)

        let observerTask = Task {
            await viewModel.startObserving()
        }
        await Task.yield()
        observerTask.cancel()
        await observerTask.value
    }
}
