import Observation
import SampleTVDomain

@MainActor
@Observable
public final class DetailsViewModel {
    public enum State: Equatable {
        case loading
        case loaded(MediaDetails)
        case failed(MediaError)
    }

    public private(set) var state: State = .loading
    public let item: MediaItem

    private let getDetails: GetMediaDetails

    public init(item: MediaItem, getDetails: GetMediaDetails) {
        self.item = item
        self.getDetails = getDetails
    }

    public func load() async {
        state = .loading
        do {
            state = .loaded(try await getDetails(item.id))
        } catch is CancellationError {
            return
        } catch {
            state = .failed(error as? MediaError ?? .unknown)
        }
    }
}
