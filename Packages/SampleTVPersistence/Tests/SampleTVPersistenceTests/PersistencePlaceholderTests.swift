import Testing
@testable import SampleTVPersistence

@Suite struct PersistencePlaceholderTests {
    @Test func resilientContainerInitializes() {
        _ = PersistenceContainer.makeResilientModelContainer()
    }
}
