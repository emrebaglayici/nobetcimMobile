import CoreLocation
import Foundation
@testable import nobetcim

final class MockPharmacyRepository: PharmacyRepositoryProtocol {
    struct NearbyCall: Equatable {
        let forceRefresh: Bool
        let ignoreThrottle: Bool
    }

    var nearbyCalls: [NearbyCall] = []
    var nearbyResults: [Pharmacy] = []
    var nearbyError: Error?

    var cityResults: [Pharmacy] = []
    var cityError: Error?

    func fetchNearby(
        latitude: CLLocationDegrees,
        longitude: CLLocationDegrees,
        forceRefresh: Bool,
        ignoreThrottle: Bool
    ) async throws -> [Pharmacy] {
        nearbyCalls.append(NearbyCall(forceRefresh: forceRefresh, ignoreThrottle: ignoreThrottle))
        if let nearbyError { throw nearbyError }
        return nearbyResults
    }

    func fetchByCity(
        city: String,
        district: String?,
        forceRefresh: Bool,
        directory: [CityDistrict]?
    ) async throws -> [Pharmacy] {
        if let cityError { throw cityError }
        return cityResults
    }

    func loadDirectory(forceRefresh: Bool) async -> [CityDistrict] {
        []
    }

    func loadDistricts(for city: String, forceRefresh: Bool) async -> [String] {
        []
    }
}
