import CoreLocation
import Foundation

protocol PharmacyRepositoryProtocol {
    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, forceRefresh: Bool) async throws -> [Pharmacy]
    func fetchByCity(city: String, district: String?, forceRefresh: Bool) async throws -> [Pharmacy]
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
        directoryCache: PersistentCacheStore<[CityDistrict]> = PersistentCacheStore(key: "nobetcim.location.directory")
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
            let sorted = cached.sortedByDistance(from: CLLocation(latitude: latitude, longitude: longitude))
            NearestPharmacyWidgetStore.save(Array(sorted.prefix(2)))
            return sorted
        }

        do {
            #if DEBUG
            print("NobetEcza daily cache miss: nearby")
            #endif
            let remote = try await pharmacyService.fetchNearby(latitude: latitude, longitude: longitude, radius: 50000)
            let sorted = remote.sortedByDistance(from: CLLocation(latitude: latitude, longitude: longitude))
            cache.saveToday(sorted)
            NearestPharmacyWidgetStore.save(Array(sorted.prefix(2)))
            return sorted
        } catch {
            if let stale = cache.loadAnyCachedValue(), !stale.isEmpty {
                let sorted = stale.sortedByDistance(from: CLLocation(latitude: latitude, longitude: longitude))
                NearestPharmacyWidgetStore.save(Array(sorted.prefix(2)))
                return sorted
            }
            throw error
        }
    }

    func fetchByCity(city: String, district: String?, forceRefresh: Bool = false) async throws -> [Pharmacy] {
        let cityInfo = cityInfo(for: city)
        let citySlug = cityInfo?.citySlug ?? city.slugifiedTurkish
        let districtSlug = cityInfo?.slug(forDistrict: district) ?? district?.slugifiedTurkish
        let districtCachePart = districtSlug ?? "all"
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
            let remote = try await pharmacyService.fetchDutyPharmacies(citySlug: citySlug, districtSlug: districtSlug)
            let sorted = remote.sortedByDistrictAndName()
            cache.saveToday(sorted)
            return sorted
        } catch {
            if let stale = cache.loadAnyCachedValue(), !stale.isEmpty {
                return stale.sortedByDistrictAndName()
            }
            throw error
        }
    }

    func loadDirectory(forceRefresh: Bool = false) async -> [CityDistrict] {
        if !forceRefresh, let cached = directoryCache.load(), !cached.isEmpty {
            return cached
        }

        do {
            let remote = try await directoryService.fetchCities()
            if !remote.isEmpty {
                directoryCache.save(remote)
                return remote
            }
        } catch {
            #if DEBUG
            print("Location directory fetch failed:", error)
            #endif
        }

        if let cached = directoryCache.load(), !cached.isEmpty {
            return cached
        }

        return []
    }

    func loadDistricts(for city: String, forceRefresh: Bool = false) async -> [String] {
        guard let cityInfo = cityInfo(for: city) else { return [] }
        if !forceRefresh, !cityInfo.districts.isEmpty {
            return cityInfo.districts
        }

        let cache = PersistentCacheStore<[DistrictInfo]>(key: "nobetcim.location.districts.\(cityInfo.citySlug)")
        if !forceRefresh, let cached = cache.load(), !cached.isEmpty {
            mergeDistricts(cached, into: cityInfo)
            return cached.map(\.name).sortedTurkish
        }

        do {
            let remote = try await directoryService.fetchDistricts(citySlug: cityInfo.citySlug)
            if !remote.isEmpty {
                cache.save(remote)
                mergeDistricts(remote, into: cityInfo)
                return remote.map(\.name).sortedTurkish
            }
        } catch {
            #if DEBUG
            print("District fetch failed:", error)
            #endif
        }

        return []
    }

    private func cityInfo(for city: String) -> CityDistrict? {
        directoryCache.load()?.first { $0.city.matchesTurkish(city) || $0.citySlug == city.slugifiedTurkish }
    }

    private func mergeDistricts(_ districts: [DistrictInfo], into cityInfo: CityDistrict) {
        var directory = directoryCache.load() ?? []
        let districtNames = districts.map(\.name).sortedTurkish
        let districtSlugs = Dictionary(uniqueKeysWithValues: districts.map { ($0.name, $0.slug) })
        let updated = CityDistrict(
            city: cityInfo.city,
            citySlug: cityInfo.citySlug,
            districts: districtNames,
            districtSlugs: districtSlugs
        )

        if let index = directory.firstIndex(where: { $0.citySlug == cityInfo.citySlug }) {
            directory[index] = updated
        } else {
            directory.append(updated)
        }
        directoryCache.save(directory.cleaned)
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

private extension String {
    func matchesTurkish(_ other: String) -> Bool {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR")) ==
            other.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
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
