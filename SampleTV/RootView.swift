import SwiftUI

struct RootView: View {
    let container: AppContainer

    var body: some View {
        if container.configuration.hasToken {
            Text("SampleTV")
        } else {
            ContentUnavailableView(
                "TMDB token missing",
                systemImage: "key.slash",
                description: Text("Copy Config/Secrets.xcconfig.example to Config/Secrets.xcconfig and add your token.")
            )
        }
    }
}
