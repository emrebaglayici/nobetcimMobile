import CoreLocation
import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

struct NearestPharmacyWidgetPayload: Codable {
    let id: String
    let name: String
    let district: String
    let city: String
    let address: String
    let phone: String?
    let distanceKm: Double?
    let cachedAt: Date

    init(pharmacy: Pharmacy, cachedAt: Date = Date()) {
        id = pharmacy.id
        name = pharmacy.displayName
        district = pharmacy.displayDistrict
        city = pharmacy.displayCity
        address = pharmacy.displayAddress
        phone = pharmacy.phone
        distanceKm = pharmacy.distanceKm
        self.cachedAt = cachedAt
    }
}

private struct WidgetLocationAnchor: Codable {
    let latitude: Double
    let longitude: Double
    let updatedAt: Date
}

enum NearestPharmacyWidgetStore {
    private static let pharmaciesKey = "nobetcim.widget.nearestPharmacies"
    private static let anchorKey = "nobetcim.widget.locationAnchor"
    private static let refreshDistanceMeters: CLLocationDistance = 400

    static func save(_ pharmacies: [Pharmacy], anchor: CLLocationCoordinate2D? = nil) {
        guard let defaults = UserDefaults(suiteName: AppConfig.appGroupID) else { return }
        let payloads = pharmacies.prefix(2).map { NearestPharmacyWidgetPayload(pharmacy: $0) }

        if !payloads.isEmpty, let data = try? JSONEncoder().encode(payloads) {
            defaults.set(data, forKey: pharmaciesKey)
        } else {
            defaults.removeObject(forKey: pharmaciesKey)
        }

        if let anchor {
            let anchorPayload = WidgetLocationAnchor(
                latitude: anchor.latitude,
                longitude: anchor.longitude,
                updatedAt: Date()
            )
            if let data = try? JSONEncoder().encode(anchorPayload) {
                defaults.set(data, forKey: anchorKey)
            }
        }

        reloadWidgetTimelines()
    }

    static func save(_ pharmacy: Pharmacy?) {
        if let pharmacy {
            save([pharmacy], anchor: pharmacy.coordinate)
        } else {
            save([])
        }
    }

    static func shouldRefresh(for coordinate: CLLocationCoordinate2D) -> Bool {
        guard let anchor = loadAnchor() else { return true }
        let previous = CLLocation(latitude: anchor.latitude, longitude: anchor.longitude)
        let current = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return previous.distance(from: current) >= refreshDistanceMeters
    }

    private static func loadAnchor() -> WidgetLocationAnchor? {
        guard
            let defaults = UserDefaults(suiteName: AppConfig.appGroupID),
            let data = defaults.data(forKey: anchorKey)
        else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetLocationAnchor.self, from: data)
    }

    private static func reloadWidgetTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "NearestPharmacyWidget")
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}
