import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct CategoriesView: View {
    @State private var viewModel: CategoriesViewModel
    private let onSelectCategory: (MediaKind, Genre) -> Void
    private let onSelectKind: (MediaKind) -> Void

    public init(
        viewModel: CategoriesViewModel,
        onSelectCategory: @escaping (MediaKind, Genre) -> Void,
        onSelectKind: @escaping (MediaKind) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectCategory = onSelectCategory
        self.onSelectKind = onSelectKind
    }

    public var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .failed(let error):
                ErrorView(error: error) { Task { await viewModel.load() } }
            case .loaded(let movies, let tvShows):
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        genreSection(title: "Movies", kind: .movie, genres: movies)
                        genreSection(title: "TV Shows", kind: .tv, genres: tvShows)
                    }
                    .padding(60)
                }
            }
        }
        .navigationTitle("Categories")
        .task { await viewModel.load() }
    }

    private func genreSection(title: String, kind: MediaKind, genres: [Genre]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) {
                    CategoryTile(title: "All \(title)") {
                        onSelectKind(kind)
                    }
                    ForEach(genres) { genre in
                        CategoryTile(title: genre.name) {
                            onSelectCategory(kind, genre)
                        }
                    }
                }
            }
        }
    }
}
