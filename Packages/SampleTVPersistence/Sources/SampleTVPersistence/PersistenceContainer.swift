import Foundation
import SwiftData

public enum PersistenceContainer {
    public static func makeModelContainer(inMemory: Bool = false) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        return try ModelContainer(
            for: StoredProfile.self,
            StoredPreferences.self,
            StoredWatchlistItem.self,
            StoredProgress.self,
            configurations: configuration
        )
    }

    /// Creates the shared persistent `ModelContainer`, degrading gracefully to an
    /// in-memory store if disk initialization or migration fails.
    public static func makeResilientModelContainer() -> ModelContainer {
        if let container = try? makeModelContainer(inMemory: false) {
            return container
        }
        do {
            return try makeModelContainer(inMemory: true)
        } catch {
            preconditionFailure("Unable to initialize in-memory SwiftData container: \(error)")
        }
    }
}
