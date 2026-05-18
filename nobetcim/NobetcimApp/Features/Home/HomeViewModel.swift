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
        locationDirectory.first { $0.city == selectedCity }?.districts ?? []
    }

    func updateDistrictForSelectedCity() {
        selectedDistrict = ""
    }

    func loadDistrictsForSelectedCity() async {
        guard !selectedCity.isEmpty else { return }
        let districtNames = await repository.loadDistricts(for: selectedCity, forceRefresh: false)
        guard !districtNames.isEmpty else { return }

        if let index = locationDirectory.firstIndex(where: { $0.city == selectedCity }) {
            let current = locationDirectory[index]
            locationDirectory[index] = CityDistrict(
                city: current.city,
                citySlug: current.citySlug,
                districts: districtNames,
                districtSlugs: current.districtSlugs
            )
        }

        if !districts.contains(selectedDistrict) {
            selectedDistrict = ""
        }
    }

    func loadDirectory() async {
        guard locationDirectory.isEmpty else { return }
        isLoadingDirectory = true
        defer { isLoadingDirectory = false }

        let directory = await repository.loadDirectory(forceRefresh: false)
        locationDirectory = directory

        if !directory.contains(where: { $0.city == selectedCity }) {
            selectedCity = directory.first?.city ?? selectedCity
        }
        if !districts.contains(selectedDistrict) {
            selectedDistrict = ""
        }

        await loadDistrictsForSelectedCity()
    }

    func search(
        locationManager: LocationManager,
        forceRefresh: Bool = false,
        isPullToRefresh: Bool = false
    ) async -> Bool {
        let hadExistingResults = !pharmacies.isEmpty
        isLoading = true
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
                pharmacies = try await repository.fetchNearby(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    forceRefresh: forceRefresh
                )
            case .city:
                pharmacies = try await repository.fetchByCity(
                    city: selectedCity,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict,
                    forceRefresh: forceRefresh
                )
            }

            if locationDirectory.isEmpty {
                locationDirectory = pharmacies.derivedDirectory
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
