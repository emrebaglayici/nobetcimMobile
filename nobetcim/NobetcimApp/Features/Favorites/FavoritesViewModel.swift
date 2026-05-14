import Combine
import Foundation

@MainActor
final class FavoritesViewModel: ObservableObject {
    @Published var searchText = ""

    func filteredFavorites(from favorites: [Pharmacy]) -> [Pharmacy] {
        guard !searchText.isEmpty else { return favorites }
        return favorites.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.city.localizedCaseInsensitiveContains(searchText)
                || $0.district.localizedCaseInsensitiveContains(searchText)
        }
    }
}
