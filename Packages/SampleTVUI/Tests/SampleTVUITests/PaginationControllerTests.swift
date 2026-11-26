import Foundation
import SampleTVDomain
import Testing
@testable import SampleTVUI

@MainActor
struct PaginationControllerTests {
    private struct MockElement: Sendable, Equatable {
        let id: String
        let name: String
    }

    @Test func reloadPopulatesPage1AndCanLoadMore() async {
        let controller = PaginationController<MockElement>()
        await controller.reload { page in
            #expect(page == 1)
            return ResultPage(items: [MockElement(id: "1", name: "Item 1")], page: 1, totalPages: 2)
        }

        #expect(controller.state == .loaded([MockElement(id: "1", name: "Item 1")]))
        #expect(controller.canLoadMore == true)
        #expect(controller.isLoading == false)
    }

    @Test func canLoadMoreReturnsFalseWhenOnLastPage() async {
        let controller = PaginationController<MockElement>()
        await controller.reload { _ in
            ResultPage(items: [MockElement(id: "1", name: "Item 1")], page: 1, totalPages: 1)
        }

        #expect(controller.canLoadMore == false)
    }

    @Test func loadNextPageAppendsPage2() async {
        let controller = PaginationController<MockElement>()
        await controller.reload { _ in
            ResultPage(items: [MockElement(id: "1", name: "Item 1")], page: 1, totalPages: 2)
        }

        await controller.loadNextPage { page in
            #expect(page == 2)
            return ResultPage(items: [MockElement(id: "2", name: "Item 2")], page: 2, totalPages: 2)
        }

        #expect(controller.items.map(\.id) == ["1", "2"])
        #expect(controller.canLoadMore == false)
        #expect(controller.isLoadingNextPage == false)
    }

    @Test func reloadErrorSetsFailedStateAndLoadNextPageSetsError() async {
        let failingController = PaginationController<MockElement>()
        await failingController.reload { _ in throw MediaError.offline }
        #expect(failingController.state == .failed(.offline))

        let controller = PaginationController<MockElement>()
        await controller.reload { _ in
            ResultPage(items: [MockElement(id: "1", name: "Item 1")], page: 1, totalPages: 2)
        }
        await controller.loadNextPage { _ in throw MediaError.rateLimited(retryAfter: 5) }

        #expect(controller.error == .rateLimited(retryAfter: 5))
        #expect(controller.canLoadMore == false)
        #expect(controller.items.count == 1)
    }

    @Test func cancellationErrorDoesNotSetFailedState() async {
        let controller = PaginationController<MockElement>()
        await controller.reload { _ in
            ResultPage(items: [MockElement(id: "1", name: "Item 1")], page: 1, totalPages: 2)
        }
        await controller.loadNextPage { _ in throw CancellationError() }

        #expect(controller.state == .loaded([MockElement(id: "1", name: "Item 1")]))
        #expect(controller.error == nil)
    }

    @Test func mediaErrorAndAuthErrorUserMessagesAreNonEmpty() {
        let mediaErrors: [MediaError] = [
            .offline,
            .unauthorized,
            .notFound,
            .rateLimited(retryAfter: 10),
            .server(statusCode: 500),
            .decoding,
            .unknown
        ]
        for error in mediaErrors {
            #expect(!error.userMessage.isEmpty)
        }

        let authErrors: [AuthError] = [.emptyFields, .invalidCredentials, .sessionExpired]
        for error in authErrors {
            #expect(!error.userMessage.isEmpty)
        }
    }
}
