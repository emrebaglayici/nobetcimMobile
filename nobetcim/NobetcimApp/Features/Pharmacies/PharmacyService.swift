import CoreLocation
import Foundation

protocol PharmacyServiceProtocol {
    func fetchDutyPharmacies(citySlug: String, districtSlug: String?) async throws -> [Pharmacy]
    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int) async throws -> [Pharmacy]
    func fetchCatalogPharmacies(citySlug: String?, districtSlug: String?, page: Int, limit: Int) async throws -> [Pharmacy]
    func fetchNearbyCatalog(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int, limit: Int, citySlug: String?, districtSlug: String?) async throws -> [Pharmacy]
}

protocol NotaryServiceProtocol {
    func fetchDutyNotaries(citySlug: String, districtSlug: String?) async throws -> [Pharmacy]
    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int) async throws -> [Pharmacy]
    func fetchCatalogNotaries(citySlug: String?, districtSlug: String?, page: Int, limit: Int) async throws -> [Pharmacy]
}

final class PharmacyService: PharmacyServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchDutyPharmacies(citySlug: String, districtSlug: String?) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.dutyPharmacies(citySlug: citySlug, districtSlug: districtSlug), as: PharmacyResponse.self)
        return response.pharmacies
    }

    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int = 3000) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.nearby(latitude: latitude, longitude: longitude, radius: radius), as: PharmacyResponse.self)
        return response.pharmacies
    }

    func fetchCatalogPharmacies(citySlug: String?, districtSlug: String?, page: Int = 1, limit: Int = 100) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.pharmacyCatalog(citySlug: citySlug, districtSlug: districtSlug, page: page, limit: limit), as: PharmacyResponse.self)
        return response.pharmacies
    }

    func fetchNearbyCatalog(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int = 50000, limit: Int = 50, citySlug: String? = nil, districtSlug: String? = nil) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.nearbyCatalog(latitude: latitude, longitude: longitude, radius: radius, limit: limit, citySlug: citySlug, districtSlug: districtSlug), as: PharmacyResponse.self)
        return response.pharmacies
    }
}

final class NotaryService: NotaryServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchDutyNotaries(citySlug: String, districtSlug: String?) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.dutyNotaries(citySlug: citySlug, districtSlug: districtSlug), as: PharmacyResponse.self)
        return response.pharmacies
    }

    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int = 50000) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.nearbyNotaries(latitude: latitude, longitude: longitude, radius: radius), as: PharmacyResponse.self)
        return response.pharmacies
    }

    func fetchCatalogNotaries(citySlug: String?, districtSlug: String?, page: Int = 1, limit: Int = 100) async throws -> [Pharmacy] {
        let response = try await apiClient.send(.notaryCatalog(citySlug: citySlug, districtSlug: districtSlug, page: page, limit: limit), as: PharmacyResponse.self)
        return response.pharmacies
    }
}

struct PharmacyResponse: Decodable {
    let pharmacies: [Pharmacy]

    enum CodingKeys: String, CodingKey {
        case pharmacies
        case data
        case results
        case items
    }

    init(from decoder: Decoder) throws {
        if let array = try? [Pharmacy](from: decoder) {
            pharmacies = array
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        pharmacies = try container.decodeIfPresent([Pharmacy].self, forKey: .pharmacies)
            ?? container.decodeIfPresent([Pharmacy].self, forKey: .data)
            ?? container.decodeIfPresent([Pharmacy].self, forKey: .results)
            ?? container.decodeIfPresent([Pharmacy].self, forKey: .items)
            ?? []
    }
}
