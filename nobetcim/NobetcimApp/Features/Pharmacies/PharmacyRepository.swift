import CoreLocation
import Foundation

protocol PharmacyRepositoryProtocol {
    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, forceRefresh: Bool) async throws -> [Pharmacy]
    func fetchByCity(city: String, district: String?, forceRefresh: Bool, directory: [CityDistrict]?) async throws -> [Pharmacy]
    func loadDirectory(forceRefresh: Bool) async -> [CityDistrict]
    func loadDistricts(for city: String, forceRefresh: Bool) async -> [String]
}

final class PharmacyRepository: PharmacyRepositoryProtocol {
    private let pharmacyService: PharmacyServiceProtocol
    private let directoryService: LocationDirectoryServiceProtocol
    private let directoryCache: PersistentCacheStore<[CityDistrict]>

    init(
        pharmacyService: PharmacyServiceProtocol = PharmacyService(),
        directoryService: LocationDirectoryServiceProtocol = LocationDirectoryService(),
        directoryCache: PersistentCacheStore<[CityDistrict]> = PersistentCacheStore(key: "nobetcim.location.directory.v3")
    ) {
        self.pharmacyService = pharmacyService
        self.directoryService = directoryService
        self.directoryCache = directoryCache
    }

    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, forceRefresh: Bool = false) async throws -> [Pharmacy] {
        let cache = DailyCacheStore<[Pharmacy]>(key: "nobetcim.daily.nearby.\(latitude.cacheCoordinateKey).\(longitude.cacheCoordinateKey)")
        if !forceRefresh, let cached = cache.loadToday() {
            #if DEBUG
            print("NobetEcza daily cache hit: nearby")
            #endif
            return finishNearby(sorted: cached.sortedByDistance(from: CLLocation(latitude: latitude, longitude: longitude)), anchor: coordinateAnchor(latitude, longitude))
        }

        do {
            #if DEBUG
            print("NobetEcza daily cache miss: nearby")
            #endif
            let remote = try await pharmacyService.fetchNearby(latitude: latitude, longitude: longitude, radius: 50000)
            let sorted = remote.sortedByDistance(from: CLLocation(latitude: latitude, longitude: longitude))
            if !sorted.isEmpty {
                cache.saveToday(sorted)
            }
            return finishNearby(sorted: sorted, anchor: coordinateAnchor(latitude, longitude))
        } catch {
            // 429/5xx: only today's cache — never yesterday's duty list (rotates daily).
            if let todayCache = cache.loadToday(), !todayCache.isEmpty, error.prefersStaleCacheFallback {
                let sorted = todayCache.sortedByDistance(from: CLLocation(latitude: latitude, longitude: longitude))
                return finishNearby(sorted: sorted, anchor: coordinateAnchor(latitude, longitude))
            }
            throw error
        }
    }

    func fetchByCity(
        city: String,
        district: String?,
        forceRefresh: Bool = false,
        directory: [CityDistrict]? = nil
    ) async throws -> [Pharmacy] {
        let cityInfo = cityInfo(for: city, in: directory)
        let citySlug = cityInfo?.citySlug ?? city.slugifiedTurkish
        let canonicalDistrict = district.map { $0.canonicalDistrictName }
        let districtCachePart = canonicalDistrict?.slugifiedTurkish ?? "all"
        let cache = DailyCacheStore<[Pharmacy]>(key: "nobetcim.daily.nobetci.\(citySlug).\(districtCachePart)")

        if !forceRefresh, let cached = cache.loadToday() {
            #if DEBUG
            print("NobetEcza daily cache hit: \(citySlug)/\(districtCachePart)")
            #endif
            return cached.sortedByDistrictAndName()
        }

        do {
            #if DEBUG
            print("NobetEcza daily cache miss: \(citySlug)/\(districtCachePart)")
            #endif
            let remote = try await fetchDutyPharmacies(
                citySlug: citySlug,
                district: canonicalDistrict,
                cityInfo: cityInfo
            )
            let sorted = remote.sortedByDistrictAndName()
            if !sorted.isEmpty {
                cache.saveToday(sorted)
            }
            return sorted
        } catch {
            if let todayCache = cache.loadToday(), !todayCache.isEmpty, error.prefersStaleCacheFallback {
                return todayCache.sortedByDistrictAndName()
            }
            throw error
        }
    }

    func loadDirectory(forceRefresh: Bool = false) async -> [CityDistrict] {
        let bundled = TurkeyLocationCatalog.allCities()
        if !bundled.isEmpty {
            directoryCache.save(bundled)
            return bundled
        }

        if !forceRefresh, let cached = directoryCache.load(), !cached.isEmpty {
            return cached
        }

        return []
    }

    func loadDistricts(for city: String, forceRefresh: Bool = false) async -> [String] {
        _ = forceRefresh
        return TurkeyLocationCatalog.districts(for: city)
    }

    /// İlçe seçildiğinde tüm alt bölgeleri (Buca 1, 2…) kapsamak için şehir geneli çekilip canonical ada göre filtrelenir.
    private func fetchDutyPharmacies(
        citySlug: String,
        district: String?,
        cityInfo: CityDistrict?
    ) async throws -> [Pharmacy] {
        guard let district, !district.isEmpty else {
            return try await pharmacyService.fetchDutyPharmacies(citySlug: citySlug, districtSlug: nil)
        }

        let districtSlug = cityInfo?.slug(forDistrict: district)
        if let districtSlug {
            let scoped = try await pharmacyService.fetchDutyPharmacies(
                citySlug: citySlug,
                districtSlug: districtSlug
            )
            if !scoped.isEmpty {
                return scoped.filter {
                    $0.district.canonicalDistrictName.matchesTurkish(district)
                }
            }
        }

        let cityWide = try await pharmacyService.fetchDutyPharmacies(citySlug: citySlug, districtSlug: nil)
        return cityWide.filter {
            $0.district.canonicalDistrictName.matchesTurkish(district)
        }
    }

    private func finishNearby(sorted: [Pharmacy], anchor: CLLocationCoordinate2D) -> [Pharmacy] {
        NearestPharmacyWidgetStore.save(Array(sorted.prefix(2)), anchor: anchor)
        return sorted
    }

    private func coordinateAnchor(_ latitude: CLLocationDegrees, _ longitude: CLLocationDegrees) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private func cityInfo(for city: String, in directory: [CityDistrict]? = nil) -> CityDistrict? {
        if let match = TurkeyLocationCatalog.entry(for: city) {
            return match
        }
        let sources = [directory, directoryCache.load()].compactMap { $0 }.filter { !$0.isEmpty }
        for list in sources {
            if let match = list.first(where: { $0.city.matchesTurkish(city) || $0.citySlug == city.slugifiedTurkish }) {
                return match
            }
        }
        return nil
    }
}

private extension Error {
    var prefersStaleCacheFallback: Bool {
        (self as? NetworkError)?.prefersStaleCache ?? false
    }
}

private extension Double {
    var cacheCoordinateKey: String {
        String(format: "%.3f", self)
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: "-", with: "m")
    }
}

private extension Array where Element == Pharmacy {
    func sortedByDistrictAndName() -> [Pharmacy] {
        sorted {
            if $0.district == $1.district {
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return $0.district.localizedStandardCompare($1.district) == .orderedAscending
        }
    }
}

extension Array where Element == Pharmacy {
    var derivedDirectory: [CityDistrict] {
        let grouped = Dictionary(grouping: self.filter { !$0.city.isEmpty }, by: \.city)
        return grouped.map { city, pharmacies in
            CityDistrict(
                city: city,
                districts: Swift.Array(Swift.Set<String>(pharmacies.map(\.district).filter { !$0.isEmpty })).sortedTurkish
            )
        }
        .cleaned
    }

    func sortedByDistance(from location: CLLocation) -> [Pharmacy] {
        map { pharmacy in
            var copy = pharmacy
            if copy.distanceKm == nil, let coordinate = copy.coordinate {
                let target = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                copy.distanceKm = location.distance(from: target) / 1000
            }
            return copy
        }
        .sorted {
            ($0.distanceKm ?? .greatestFiniteMagnitude) < ($1.distanceKm ?? .greatestFiniteMagnitude)
        }
    }
}
