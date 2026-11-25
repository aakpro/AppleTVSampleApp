import SampleTVDomain
import SampleTVUI
import SwiftUI

public struct CategoriesView: View {
    private let getGenres: GetGenres
    private let onSelectCategory: (MediaKind, Genre) -> Void
    private let onSelectKind: (MediaKind) -> Void

    @State private var movieGenres: [Genre] = []
    @State private var tvGenres: [Genre] = []
    @State private var isLoading = false

    public init(
        getGenres: GetGenres,
        onSelectCategory: @escaping (MediaKind, Genre) -> Void,
        onSelectKind: @escaping (MediaKind) -> Void
    ) {
        self.getGenres = getGenres
        self.onSelectCategory = onSelectCategory
        self.onSelectKind = onSelectKind
    }

    public var body: some View {
        Group {
            if isLoading && movieGenres.isEmpty && tvGenres.isEmpty {
                ProgressView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 40) {
                        genreSection(title: "Movies", kind: .movie, genres: movieGenres)
                        genreSection(title: "TV Shows", kind: .tv, genres: tvGenres)
                    }
                    .padding(60)
                }
            }
        }
        .navigationTitle("Categories")
        .task {
            await loadGenres()
        }
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

    private func loadGenres() async {
        isLoading = true
        defer { isLoading = false }
        async let movies = try? getGenres(for: .movie)
        async let shows = try? getGenres(for: .tv)
        movieGenres = (await movies) ?? []
        tvGenres = (await shows) ?? []
    }
}
