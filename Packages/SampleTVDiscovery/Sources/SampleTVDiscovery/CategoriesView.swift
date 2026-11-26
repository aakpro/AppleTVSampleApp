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
                    VStack(alignment: .leading, spacing: 36) {
                        genreSection(title: "Movies", kind: .movie, genres: movies)
                        genreSection(title: "TV Shows", kind: .tv, genres: tvShows)
                    }
                    .padding(.vertical, 48)
                }
            }
        }
        .navigationTitle("Categories")
        .task { await viewModel.load() }
    }

    private func genreSection(title: String, kind: MediaKind, genres: [Genre]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(SampleTVTheme.Typography.sectionTitle)
                .padding(.horizontal, SampleTVTheme.horizontalSafeMargin)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: SampleTVTheme.shelfItemSpacing) {
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
            .contentMargins(.horizontal, SampleTVTheme.horizontalSafeMargin, for: .scrollContent)
            .contentMargins(.vertical, SampleTVTheme.shelfVerticalMargin, for: .scrollContent)
            .scrollClipDisabled()
        }
    }
}
