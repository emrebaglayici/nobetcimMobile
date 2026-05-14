import CoreLocation
import Foundation

protocol PharmacyServiceProtocol {
    func fetchDutyPharmacies(citySlug: String, districtSlug: String?) async throws -> [Pharmacy]
    func fetchNearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int) async throws -> [Pharmacy]
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
