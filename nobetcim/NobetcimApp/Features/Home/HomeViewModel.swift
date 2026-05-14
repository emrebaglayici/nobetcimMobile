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

    func search(locationManager: LocationManager) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer {
            isLoading = false
            hasSearched = true
        }

        do {
            switch searchMode {
            case .nearby:
                let location = try await locationManager.requestLocation()
                pharmacies = try await repository.fetchNearby(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    forceRefresh: false
                )
            case .city:
                pharmacies = try await repository.fetchByCity(
                    city: selectedCity,
                    district: selectedDistrict.isEmpty ? nil : selectedDistrict,
                    forceRefresh: false
                )
            }

            if locationDirectory.isEmpty {
                locationDirectory = pharmacies.derivedDirectory
            }

            if pharmacies.isEmpty {
                errorMessage = "Bu bölgede nöbetçi eczane bulunamadı."
            }
            return !pharmacies.isEmpty
        } catch let error as NetworkError {
            errorMessage = error.localizedDescription
        } catch let error as LocationError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Eczane bilgileri alınamadı."
        }
        return false
    }

    func usePreviewData() {
        pharmacies = Pharmacy.previews
        hasSearched = true
    }
}

typealias HomeViewModel = PharmacyViewModel
