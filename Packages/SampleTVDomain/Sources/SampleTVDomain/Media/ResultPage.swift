import Foundation

public struct ResultPage<Element: Sendable & Equatable>: Sendable, Equatable {
    public let items: [Element]
    public let page: Int
    public let totalPages: Int

    public var hasNextPage: Bool { page < totalPages }

    public init(items: [Element], page: Int, totalPages: Int) {
        self.items = items
        self.page = page
        self.totalPages = totalPages
    }

    public static var empty: ResultPage { .init(items: [], page: 1, totalPages: 1) }
}
