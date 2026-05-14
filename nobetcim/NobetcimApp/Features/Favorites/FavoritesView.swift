import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var favoritesStore: FavoritesStore
    @StateObject private var viewModel = FavoritesViewModel()

    var body: some View {
        ScrollView {
            let favorites = viewModel.filteredFavorites(from: favoritesStore.favorites)
            LazyVStack(spacing: 14) {
                if favorites.isEmpty {
                    EmptyStateView(
                        title: "Henüz favori eklemediniz.",
                        message: "Sık kullandığınız eczaneleri kalp simgesiyle kaydedebilirsiniz.",
                        systemImage: "heart"
                    )
                } else {
                    ForEach(favorites) { pharmacy in
                        PharmacyCardView(pharmacy: pharmacy)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Favoriler")
        .searchable(text: $viewModel.searchText, prompt: "Favorilerde ara")
    }
}

#Preview {
    NavigationStack {
        FavoritesView()
    }
    .environmentObject(FavoritesStore())
}
