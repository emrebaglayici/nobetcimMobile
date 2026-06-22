import Foundation

protocol LocationDirectoryServiceProtocol {
    func fetchCities() async throws -> [CityDistrict]
    func fetchDistricts(citySlug: String, type: APIEndpoint.DirectoryKind?) async throws -> [DistrictInfo]
}

final class LocationDirectoryService: LocationDirectoryServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchCities() async throws -> [CityDistrict] {
        let response = try await apiClient.send(.cities, as: CityDistrictResponse.self)
        return response.items
    }

    func fetchDistricts(citySlug: String, type: APIEndpoint.DirectoryKind? = nil) async throws -> [DistrictInfo] {
        let response = try await apiClient.send(.districts(citySlug: citySlug, type: type), as: DistrictResponse.self)
        return response.items
    }
}
