import CoreLocation
import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

enum APIEndpoint {
    case dutyPharmacies(citySlug: String, districtSlug: String?)
    case nearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int)
    case cities
    case districts(citySlug: String)

    var method: HTTPMethod { .get }

    var path: String {
        switch self {
        case .dutyPharmacies:
            "/v1/nobetci"
        case .nearby:
            "/v1/konum"
        case .cities:
            "/v1/iller"
        case .districts:
            "/v1/ilceler"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case let .dutyPharmacies(citySlug, districtSlug):
            [
                URLQueryItem(name: "il", value: citySlug),
                URLQueryItem(name: "ilce", value: districtSlug)
            ].compactMap { $0.value?.isEmpty == false ? $0 : nil }
        case let .nearby(latitude, longitude, radius):
            [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lng", value: String(longitude)),
                URLQueryItem(name: "radius", value: String(radius))
            ]
        case .cities:
            []
        case let .districts(citySlug):
            [URLQueryItem(name: "il", value: citySlug)]
        }
    }

    func makeRequest(baseURL: URL, apiKey: String) throws -> URLRequest {
        guard !apiKey.isEmpty else { throw NetworkError.missingAPIKey }
        guard var components = URLComponents(url: baseURL.appending(path: path), resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = queryItems
        guard let url = components.url else { throw NetworkError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.timeoutInterval = 20
        return request
    }
}
