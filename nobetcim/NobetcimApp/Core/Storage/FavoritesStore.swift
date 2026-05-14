import Combine
import Foundation

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: [Pharmacy] = []

    private let key = "nobetcim.favorite.pharmacies"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        load()
    }

    func isFavorite(_ pharmacy: Pharmacy) -> Bool {
        favorites.contains { $0.id == pharmacy.id }
    }

    func toggle(_ pharmacy: Pharmacy) {
        if let index = favorites.firstIndex(where: { $0.id == pharmacy.id }) {
            favorites.remove(at: index)
        } else {
            favorites.insert(pharmacy, at: 0)
        }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key) else { return }
        favorites = (try? decoder.decode([Pharmacy].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? encoder.encode(favorites) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
