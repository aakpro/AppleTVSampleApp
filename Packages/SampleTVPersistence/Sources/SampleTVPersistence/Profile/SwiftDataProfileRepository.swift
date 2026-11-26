import Foundation
import SampleTVDomain
import SwiftData

/// SwiftData-backed profile and preferences repository.
@ModelActor
public actor SwiftDataProfileRepository: ProfileRepository {
    public init(inMemory: Bool = false) throws {
        let container = try PersistenceContainer.makeModelContainer(inMemory: inMemory)
        self.init(modelContainer: container)
    }

    public func currentProfile() async throws -> ViewerProfile {
        try seedIfNeeded()
        let descriptor = FetchDescriptor<StoredProfile>(
            predicate: #Predicate { $0.isActive }
        )
        if let active = try modelContext.fetch(descriptor).first {
            return ViewerProfile(id: active.id, name: active.name, isMain: active.isMain)
        }
        let all = try await profiles()
        if let first = all.first {
            return first
        }
        return ViewerProfile(id: ViewerProfile.defaultID, name: "Main", isMain: true)
    }

    public func profiles() async throws -> [ViewerProfile] {
        try seedIfNeeded()
        let descriptor = FetchDescriptor<StoredProfile>()
        let stored = try modelContext.fetch(descriptor)
        return stored
            .map { ViewerProfile(id: $0.id, name: $0.name, isMain: $0.isMain) }
            .sorted { lhs, rhs in
                if lhs.isMain != rhs.isMain {
                    return lhs.isMain
                }
                return lhs.name < rhs.name
            }
    }

    public func preferences(for profileID: String) async throws -> UserPreferences {
        try seedIfNeeded()
        let targetProfileID = profileID
        let descriptor = FetchDescriptor<StoredPreferences>(
            predicate: #Predicate { $0.profileID == targetProfileID }
        )
        guard let stored = try modelContext.fetch(descriptor).first else {
            return UserPreferences()
        }
        let kind = MediaKind(rawValue: stored.defaultKindRaw) ?? .movie
        return UserPreferences(defaultKind: kind, autoplayTrailers: stored.autoplayTrailers)
    }

    public func updatePreferences(_ preferences: UserPreferences, for profileID: String) async throws {
        try seedIfNeeded()
        let targetProfileID = profileID
        let descriptor = FetchDescriptor<StoredPreferences>(
            predicate: #Predicate { $0.profileID == targetProfileID }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            existing.defaultKindRaw = preferences.defaultKind.rawValue
            existing.autoplayTrailers = preferences.autoplayTrailers
        } else {
            let created = StoredPreferences(
                profileID: profileID,
                defaultKindRaw: preferences.defaultKind.rawValue,
                autoplayTrailers: preferences.autoplayTrailers
            )
            modelContext.insert(created)
        }
        try modelContext.save()
    }

    public func switchProfile(to profileID: String) async throws {
        try seedIfNeeded()
        let descriptor = FetchDescriptor<StoredProfile>()
        let stored = try modelContext.fetch(descriptor)
        for profile in stored {
            profile.isActive = (profile.id == profileID)
        }
        try modelContext.save()
    }

    private func seedIfNeeded() throws {
        let descriptor = FetchDescriptor<StoredProfile>()
        let existing = try modelContext.fetch(descriptor)
        guard existing.isEmpty else { return }

        let defaults = [
            StoredProfile(id: ViewerProfile.defaultID, name: "Main", isMain: true, isActive: true),
            StoredProfile(id: "kids", name: "Kids", isMain: false, isActive: false),
            StoredProfile(id: "guest", name: "Guest", isMain: false, isActive: false)
        ]
        for profile in defaults {
            modelContext.insert(profile)
        }
        try modelContext.save()
    }
}
