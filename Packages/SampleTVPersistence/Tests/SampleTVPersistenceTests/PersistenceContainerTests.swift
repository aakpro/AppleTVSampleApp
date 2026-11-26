import SwiftData
import Testing
@testable import SampleTVPersistence

@Suite struct PersistenceContainerTests {
    @Test func makeModelContainerInMemoryCreatesValidContainer() throws {
        let container = try PersistenceContainer.makeModelContainer(inMemory: true)
        #expect(!container.configurations.isEmpty)
    }

    @Test func makeResilientModelContainerReturnsContainer() {
        let container = PersistenceContainer.makeResilientModelContainer()
        #expect(!container.configurations.isEmpty)
    }
}
