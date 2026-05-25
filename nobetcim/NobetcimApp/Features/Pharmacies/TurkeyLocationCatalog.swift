import Foundation

/// Türkiye'nin 81 ili ve ilçeleri — picker için tek kaynak (API nöbet bölgeleri değil).
enum TurkeyLocationCatalog {
    private static let bundled: [CityDistrict] = loadBundled()

    static func allCities() -> [CityDistrict] {
        bundled
    }

    static func districts(for city: String) -> [String] {
        entry(for: city)?.districts ?? []
    }

    static func entry(for city: String) -> CityDistrict? {
        bundled.first { $0.city.matchesTurkish(city) }
    }

    private static func loadBundled() -> [CityDistrict] {
        guard
            let url = Bundle.main.url(forResource: "TurkeyLocations", withExtension: "json"),
            let data = try? Data(contentsOf: url)
        else {
            #if DEBUG
            print("TurkeyLocationCatalog: TurkeyLocations.json missing from bundle")
            #endif
            return []
        }

        do {
            let decoded = try JSONDecoder().decode([CityDistrict].self, from: data)
            return decoded.cleaned
        } catch {
            #if DEBUG
            print("TurkeyLocationCatalog decode failed:", error)
            #endif
            return []
        }
    }
}
