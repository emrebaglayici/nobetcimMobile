import CoreLocation
import Foundation

enum HTTPMethod: String {
    case get = "GET"
}

enum APIEndpoint {
    case dutyPharmacies(citySlug: String, districtSlug: String?)
    case nearby(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int)
    case pharmacyCatalog(citySlug: String?, districtSlug: String?, page: Int, limit: Int)
    case nearbyCatalog(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int, limit: Int, citySlug: String?, districtSlug: String?)
    case searchPharmacies(query: String, citySlug: String?)
    case pharmacyDetail(id: String)
    case dutyNotaries(citySlug: String, districtSlug: String?)
    case nearbyNotaries(latitude: CLLocationDegrees, longitude: CLLocationDegrees, radius: Int)
    case notaryCatalog(citySlug: String?, districtSlug: String?, page: Int, limit: Int)
    case searchNotaries(query: String, citySlug: String?)
    case notaryDetail(id: String)
    case cities
    case districts(citySlug: String, type: DirectoryKind? = nil)

    enum DirectoryKind: String {
        case notary = "noter"
    }

    var method: HTTPMethod { .get }

    var path: String {
        switch self {
        case .dutyPharmacies:
            "/nobetci"
        case .nearby:
            "/konum"
        case .pharmacyCatalog, .nearbyCatalog:
            "/eczaneler"
        case .searchPharmacies:
            "/eczane/ara"
        case let .pharmacyDetail(id):
            "/eczane/\(id)"
        case .dutyNotaries:
            "/nobetci-noter"
        case .nearbyNotaries:
            "/noter-konum"
        case .notaryCatalog:
            "/noterler"
        case .searchNotaries:
            "/noter/ara"
        case let .notaryDetail(id):
            "/noter/\(id)"
        case .cities:
            "/iller"
        case .districts:
            "/ilceler"
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
        case let .pharmacyCatalog(citySlug, districtSlug, page, limit),
             let .notaryCatalog(citySlug, districtSlug, page, limit):
            [
                URLQueryItem(name: "il", value: citySlug),
                URLQueryItem(name: "ilce", value: districtSlug),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "limit", value: String(limit))
            ].compactMap { $0.value?.isEmpty == false ? $0 : nil }
        case let .nearbyCatalog(latitude, longitude, radius, limit, citySlug, districtSlug):
            [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lng", value: String(longitude)),
                URLQueryItem(name: "radius", value: String(radius)),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "il", value: citySlug),
                URLQueryItem(name: "ilce", value: districtSlug)
            ].compactMap { $0.value?.isEmpty == false ? $0 : nil }
        case let .searchPharmacies(query, citySlug),
             let .searchNotaries(query, citySlug):
            [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "il", value: citySlug)
            ].compactMap { $0.value?.isEmpty == false ? $0 : nil }
        case .pharmacyDetail, .notaryDetail:
            []
        case .cities:
            []
        case let .dutyNotaries(citySlug, districtSlug):
            [
                URLQueryItem(name: "il", value: citySlug),
                URLQueryItem(name: "ilce", value: districtSlug)
            ].compactMap { $0.value?.isEmpty == false ? $0 : nil }
        case let .nearbyNotaries(latitude, longitude, radius):
            [
                URLQueryItem(name: "lat", value: String(latitude)),
                URLQueryItem(name: "lng", value: String(longitude)),
                URLQueryItem(name: "radius", value: String(radius))
            ]
        case let .districts(citySlug, type):
            [
                URLQueryItem(name: "il", value: citySlug),
                URLQueryItem(name: "tur", value: type?.rawValue)
            ].compactMap { $0.value?.isEmpty == false ? $0 : nil }
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
