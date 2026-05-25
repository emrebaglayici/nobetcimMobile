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
        isPullToRefresh: Bool = false
    ) async -> Bool {
        let hadExistingResults = !pharmacies.isEmpty
        isLoading = true
        pharmacies = []
        if !isPullToRefresh || !hadExistingResults {
            errorMessage = nil
        }
        defer {
            isLoading = false
            hasSearched = true
        }

        do {
            switch searchMode {
            case .nearby:
                let location = try await locationManager.requestLocation(preferCached: isPullToRefresh || !forceRefresh)
                let nearby = try await repository.fetchNearby(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    forceRefresh: forceRefresh
                )
                pharmacies = try await resolvePharmacyDistances(
                    nearby,
                    locationManager: locationManager,
                    origin: location
                )
            case .city:
                updateDistrictForSelectedCity()
                let cityResults = try await repository.fetchByCity(
                    city: selectedCity,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict,
                    forceRefresh: forceRefresh,
                    directory: locationDirectory
                )
                pharmacies = try await resolvePharmacyDistances(
                    cityResults,
                    locationManager: locationManager,
                    origin: nil
                )
            }

            if pharmacies.isEmpty {
                errorMessage = "Bu bölgede nöbetçi eczane bulunamadı."
            } else {
                errorMessage = nil
            }
            return !pharmacies.isEmpty
        } catch {
            if error.isBenignSearchCancellation {
                return hadExistingResults || !pharmacies.isEmpty
            }

            if isPullToRefresh, hadExistingResults {
                errorMessage = nil
                return true
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
    func refreshNearbyForWidgetIfNeeded(locationManager: LocationManager, forceRefresh: Bool = false) async {
        guard searchMode == .nearby, locationManager.isAuthorized else { return }

        locationSyncTask?.cancel()
        locationSyncTask = Task {
            do {
                let location = try await locationManager.requestLocation(preferCached: true)
                guard !Task.isCancelled else { return }

                let shouldRefresh = forceRefresh
                    || NearestPharmacyWidgetStore.shouldRefresh(for: location.coordinate)
                    || pharmacies.isEmpty

                guard shouldRefresh else { return }

                let results = try await repository.fetchNearby(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    forceRefresh: forceRefresh || NearestPharmacyWidgetStore.shouldRefresh(for: location.coordinate)
                )
                guard !Task.isCancelled else { return }

                pharmacies = results
                hasSearched = true
                if results.isEmpty {
                    errorMessage = "Bu bölgede nöbetçi eczane bulunamadı."
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
            await refreshNearbyForWidgetIfNeeded(locationManager: locationManager, forceRefresh: true)
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
        origin: CLLocation?
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

        return await PharmacyDistanceCalculator.resolveDistances(results, from: resolvedOrigin)
    }

}

typealias HomeViewModel = PharmacyViewModel

private extension Error {
    var isBenignSearchCancellation: Bool {
        if self is CancellationError { return true }
        if let urlError = self as? URLError, urlError.code == .cancelled { return true }
        let nsError = self as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}
