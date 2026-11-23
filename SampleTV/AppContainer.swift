/// Composition root. Phases 2-6 add the repository and one factory method per feature.
@MainActor
final class AppContainer {
    let configuration: AppConfiguration

    init(configuration: AppConfiguration) {
        self.configuration = configuration
    }

    static func live() -> AppContainer {
        AppContainer(configuration: AppConfiguration())
    }
}
