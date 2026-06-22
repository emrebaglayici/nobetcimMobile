import Combine
import CoreLocation
import Foundation

enum SearchMode: String, CaseIterable, Identifiable {
    case nearby = "Konumuma Göre"
    case city = "İl / İlçe"

    var id: String { rawValue }
}

@MainActor
final class PharmacyViewModel: ObservableObject {
    @Published var searchMode: SearchMode = .nearby
    @Published var selectedCity = "İstanbul"
    @Published var selectedDistrict = "Kadıköy"
    @Published var pharmacies: [Pharmacy] = []
    @Published var isLoading = false
    @Published var isLoadingDirectory = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    @Published var showsMapInline = false
    @Published private(set) var locationDirectory: [CityDistrict] = []

    private let repository: PharmacyRepositoryProtocol
    private var locationSyncTask: Task<Void, Never>?

    init(repository: PharmacyRepositoryProtocol? = nil) {
        self.repository = repository ?? PharmacyRepository()
    }

    var cities: [String] {
        locationDirectory.map(\.city)
    }

    var districts: [String] {
        TurkeyLocationCatalog.districts(for: selectedCity)
    }

    func clearResultsForModeChange() {
        pharmacies = []
        errorMessage = nil
        hasSearched = false
    }

    func updateDistrictForSelectedCity() {
        let available = districts
        if selectedDistrict.isEmpty { return }
        if !available.contains(where: { $0.matchesTurkish(selectedDistrict) }) {
            selectedDistrict = ""
        }
    }

    /// Konum izni varsa il alanını cihaz konumuna göre doldurur (ilçe değişmez).
    func applyCityFromLocation(locationManager: LocationManager) async {
        guard locationManager.isAuthorized, !locationDirectory.isEmpty else { return }

        do {
            let location = try await locationManager.requestLocation(preferCached: true)
            guard let city = try await LocationGeocoder.resolveCity(from: location) else { return }
            selectedCity = city
            updateDistrictForSelectedCity()
        } catch {
            #if DEBUG
            print("applyCityFromLocation failed:", error)
            #endif
        }
    }

    func loadDirectory() async {
        guard locationDirectory.isEmpty else { return }
        isLoadingDirectory = true
        defer { isLoadingDirectory = false }

        let directory = await repository.loadDirectory(forceRefresh: false)
        locationDirectory = directory

        if !directory.contains(where: { $0.city.matchesTurkish(selectedCity) }) {
            selectedCity = directory.first?.city ?? selectedCity
        }
        updateDistrictForSelectedCity()
    }

    func search(
        locationManager: LocationManager,
        forceRefresh: Bool = false,
        isPullToRefresh: Bool = false,
        ignoreNetworkThrottle: Bool = false
    ) async -> Bool {
        let previousPharmacies = pharmacies
        let hadExistingResults = !previousPharmacies.isEmpty
        let keepVisibleResults = isPullToRefresh && hadExistingResults

        if keepVisibleResults {
            // SwiftUI refreshable spinner is enough; don't replace the list with a loader.
        } else {
            isLoading = true
            pharmacies = []
            errorMessage = nil
        }

        defer {
            if !keepVisibleResults {
                isLoading = false
            }
            hasSearched = true
        }

        do {
            let refreshed: [Pharmacy]
            switch searchMode {
            case .nearby:
                let shouldForceNetwork = forceRefresh && !isPullToRefresh
                let location = try await locationManager.requestLocation(preferCached: isPullToRefresh || !shouldForceNetwork)
                let nearby = try await repository.fetchNearby(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    forceRefresh: shouldForceNetwork,
                    ignoreThrottle: ignoreNetworkThrottle
                )
                refreshed = try await resolvePharmacyDistances(
                    nearby,
                    locationManager: locationManager,
                    origin: location,
                    preferCachedDistances: isPullToRefresh
                )
            case .city:
                updateDistrictForSelectedCity()
                let cityResults = try await repository.fetchByCity(
                    city: selectedCity,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict,
                    forceRefresh: forceRefresh && !isPullToRefresh,
                    directory: locationDirectory
                )
                refreshed = try await resolvePharmacyDistances(
                    cityResults,
                    locationManager: locationManager,
                    origin: nil
                )
            }

            if refreshed.isEmpty {
                if keepVisibleResults {
                    pharmacies = previousPharmacies
                    errorMessage = nil
                } else {
                    pharmacies = []
                    errorMessage = "Bu bölgede eczane bulunamadı."
                }
            } else {
                pharmacies = refreshed
                errorMessage = nil
            }
            return !pharmacies.isEmpty
        } catch {
            if keepVisibleResults {
                pharmacies = previousPharmacies
                errorMessage = nil
                return true
            }

            if error.isBenignSearchCancellation {
                return false
            }

            if let networkError = error as? NetworkError {
                errorMessage = networkError.localizedDescription
            } else if let locationError = error as? LocationError {
                errorMessage = locationError.localizedDescription
            } else {
                errorMessage = "Eczane bilgileri alınamadı."
            }
            return false
        }
    }

    /// Refreshes nearby pharmacies + widget when the app becomes active or location shifts.
    func refreshNearbyForWidgetIfNeeded(locationManager: LocationManager) async {
        guard searchMode == .nearby, locationManager.isAuthorized else { return }

        locationSyncTask?.cancel()
        locationSyncTask = Task {
            do {
                let location = try await locationManager.requestLocation(preferCached: true)
                guard !Task.isCancelled else { return }

                let movedEnough = NearestPharmacyWidgetStore.shouldRefresh(for: location.coordinate)
                let shouldRefresh = movedEnough || pharmacies.isEmpty
                guard shouldRefresh else { return }

                guard let results = await WidgetLocationSyncService.sync(
                    at: location,
                    forceRefresh: false
                ) else { return }

                guard !Task.isCancelled else { return }

                pharmacies = results
                hasSearched = true
                if results.isEmpty {
                    errorMessage = "Bu bölgede eczane bulunamadı."
                } else {
                    errorMessage = nil
                }
            } catch {
                #if DEBUG
                print("Widget location sync failed:", error)
                #endif
            }
        }

        await locationSyncTask?.value
    }

    func handleSignificantLocationChange(_ location: CLLocation, locationManager: LocationManager) {
        guard searchMode == .nearby else { return }
        guard NearestPharmacyWidgetStore.shouldRefresh(for: location.coordinate) else { return }

        locationSyncTask?.cancel()
        locationSyncTask = Task {
            guard let results = await WidgetLocationSyncService.sync(at: location, forceRefresh: false) else { return }
            guard !Task.isCancelled else { return }
            pharmacies = results
            hasSearched = true
            errorMessage = results.isEmpty ? "Bu bölgede eczane bulunamadı." : nil
        }
    }

    func usePreviewData() {
        pharmacies = Pharmacy.previews
        hasSearched = true
    }

    /// Yol km'si bitmeden liste yayınlanmaz.
    private func resolvePharmacyDistances(
        _ results: [Pharmacy],
        locationManager: LocationManager,
        origin: CLLocation?,
        preferCachedDistances: Bool = false
    ) async throws -> [Pharmacy] {
        guard !results.isEmpty else { return results }

        let resolvedOrigin: CLLocation
        if let origin {
            resolvedOrigin = origin
        } else if locationManager.isAuthorized {
            resolvedOrigin = try await locationManager.requestLocation(preferCached: true)
        } else {
            throw LocationError.denied
        }

        if preferCachedDistances {
            return results.sortedByDistance(from: resolvedOrigin)
        }

        return await PharmacyDistanceCalculator.resolveDistances(results, from: resolvedOrigin)
    }

}

typealias HomeViewModel = PharmacyViewModel

@MainActor
final class NotaryViewModel: ObservableObject {
    @Published var searchMode: SearchMode = .nearby
    @Published var selectedCity = "İstanbul"
    @Published var selectedDistrict = "Kadıköy"
    @Published var notaries: [Pharmacy] = []
    @Published var isLoading = false
    @Published var isLoadingDirectory = false
    @Published var errorMessage: String?
    @Published var hasSearched = false
    @Published private(set) var locationDirectory: [CityDistrict] = []
    @Published private(set) var districtOptions: [String] = []

    private let notaryService: NotaryServiceProtocol
    private let directoryService: LocationDirectoryServiceProtocol

    init(
        notaryService: NotaryServiceProtocol = NotaryService(),
        directoryService: LocationDirectoryServiceProtocol = LocationDirectoryService()
    ) {
        self.notaryService = notaryService
        self.directoryService = directoryService
    }

    var cities: [String] {
        locationDirectory.map(\.city)
    }

    var districts: [String] {
        districtOptions.isEmpty ? TurkeyLocationCatalog.districts(for: selectedCity) : districtOptions
    }

    func clearResultsForModeChange() {
        notaries = []
        errorMessage = nil
        hasSearched = false
    }

    func updateDistrictForSelectedCity() {
        let available = districts
        if selectedDistrict.isEmpty { return }
        if !available.contains(where: { $0.matchesTurkish(selectedDistrict) }) {
            selectedDistrict = ""
        }
    }

    func loadDirectory() async {
        guard locationDirectory.isEmpty else { return }
        isLoadingDirectory = true
        defer { isLoadingDirectory = false }

        let remote = (try? await directoryService.fetchCities()) ?? []
        let directory = remote.isEmpty ? TurkeyLocationCatalog.allCities() : remote
        locationDirectory = directory

        if !directory.contains(where: { $0.city.matchesTurkish(selectedCity) }) {
            selectedCity = directory.first?.city ?? selectedCity
        }
        await loadDistrictsForSelectedCity(forceRefresh: true)
    }

    func loadDistrictsForSelectedCity(forceRefresh: Bool = false) async {
        let citySlug = cityInfo(for: selectedCity)?.citySlug ?? selectedCity.slugifiedTurkish
        if !forceRefresh, !districtOptions.isEmpty { return }
        isLoadingDirectory = true
        defer { isLoadingDirectory = false }

        let remote = (try? await directoryService.fetchDistricts(citySlug: citySlug, type: .notary).map(\.name)) ?? []
        districtOptions = remote.isEmpty ? TurkeyLocationCatalog.districts(for: selectedCity) : remote
        updateDistrictForSelectedCity()
    }

    func search(locationManager: LocationManager, forceRefresh: Bool = false, isPullToRefresh: Bool = false) async -> Bool {
        if !isPullToRefresh {
            isLoading = true
            notaries = []
            errorMessage = nil
        }
        defer {
            isLoading = false
            hasSearched = true
        }

        do {
            let refreshed: [Pharmacy]
            let usesCatalog = OperatingSchedule.notaryUsesCatalog()
            switch searchMode {
            case .nearby:
                let location = try await locationManager.requestLocation(preferCached: !forceRefresh)
                if usesCatalog {
                    let city = (try? await LocationGeocoder.resolveCity(from: location)) ?? selectedCity
                    let cityInfo = cityInfo(for: city)
                    let citySlug = cityInfo?.citySlug ?? city.slugifiedTurkish
                    let cache = DailyCacheStore<[Pharmacy]>(key: "nobetcim.daily.notary.catalog.nearby.\(citySlug)")
                    if !forceRefresh, let cached = cache.loadToday() {
                        refreshed = cached.sortedByDistance(from: location)
                    } else {
                        refreshed = try await notaryService.fetchCatalogNotaries(
                            citySlug: citySlug,
                            districtSlug: nil,
                            page: 1,
                            limit: 100
                        )
                        .sortedByDistance(from: location)
                        if !refreshed.isEmpty {
                            cache.saveToday(refreshed)
                        }
                    }
                } else {
                    let cache = DailyCacheStore<[Pharmacy]>(key: "nobetcim.daily.notary.duty.nearby.\(location.coordinate.latitude.nearbyCacheCoordinateKey).\(location.coordinate.longitude.nearbyCacheCoordinateKey)")
                    if !forceRefresh, let cached = cache.loadToday() {
                        refreshed = cached.sortedByDistance(from: location)
                    } else {
                        refreshed = try await notaryService.fetchNearby(
                            latitude: location.coordinate.latitude,
                            longitude: location.coordinate.longitude,
                            radius: 50000
                        )
                        .sortedByDistance(from: location)
                        if !refreshed.isEmpty {
                            cache.saveToday(refreshed)
                        }
                    }
                }
            case .city:
                await loadDistrictsForSelectedCity()
                updateDistrictForSelectedCity()
                let cityInfo = cityInfo(for: selectedCity)
                let citySlug = cityInfo?.citySlug ?? selectedCity.slugifiedTurkish
                let districtSlug = cityInfo?.slug(forDistrict: selectedDistrict)
                    ?? selectedDistrict.canonicalDistrictName.slugifiedTurkish
                let district = selectedDistrict.isEmpty ? nil : districtSlug
                let cacheKind = usesCatalog ? "catalog" : "duty"
                let cacheDistrict = district ?? "all"
                let cache = DailyCacheStore<[Pharmacy]>(key: "nobetcim.daily.notary.\(cacheKind).\(citySlug).\(cacheDistrict)")
                if !forceRefresh, let cached = cache.loadToday() {
                    refreshed = cached.sortedByDistrictAndNameForNotaries()
                } else {
                    if usesCatalog {
                        refreshed = try await notaryService.fetchCatalogNotaries(
                            citySlug: citySlug,
                            districtSlug: district,
                            page: 1,
                            limit: 100
                        )
                        .sortedByDistrictAndNameForNotaries()
                    } else {
                        refreshed = try await notaryService.fetchDutyNotaries(citySlug: citySlug, districtSlug: district)
                            .sortedByDistrictAndNameForNotaries()
                    }
                    if !refreshed.isEmpty {
                        cache.saveToday(refreshed)
                    }
                }
            }

            notaries = refreshed
            errorMessage = refreshed.isEmpty ? "Bu bölgede noter bulunamadı." : nil
            return !refreshed.isEmpty
        } catch {
            if error.isBenignSearchCancellation {
                return false
            }
            if let networkError = error as? NetworkError {
                errorMessage = networkError.localizedDescription
            } else if let locationError = error as? LocationError {
                errorMessage = locationError.localizedDescription
            } else {
                errorMessage = "Noter bilgileri alınamadı."
            }
            return false
        }
    }

    func usePreviewData() {
        notaries = Pharmacy.previews.map {
            Pharmacy(
                id: "notary-\($0.id)",
                name: $0.name.replacingOccurrences(of: "Eczanesi", with: "Noterliği"),
                city: $0.city,
                district: $0.district,
                address: $0.address,
                phone: $0.phone,
                latitude: $0.latitude,
                longitude: $0.longitude,
                distanceKm: $0.distanceKm
            )
        }
        hasSearched = true
    }

    private func cityInfo(for city: String) -> CityDistrict? {
        if let match = TurkeyLocationCatalog.entry(for: city) {
            return match
        }
        return locationDirectory.first { $0.city.matchesTurkish(city) || $0.citySlug == city.slugifiedTurkish }
    }
}

private extension Array where Element == Pharmacy {
    func sortedByDistrictAndNameForNotaries() -> [Pharmacy] {
        sorted {
            if $0.district == $1.district {
                return $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            return $0.district.localizedStandardCompare($1.district) == .orderedAscending
        }
    }
}

private extension Error {
    var isBenignSearchCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
