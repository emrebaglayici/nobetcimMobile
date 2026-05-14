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
        district = pharmacy.district
        city = pharmacy.city
        address = pharmacy.address
        phone = pharmacy.phone
        distanceKm = pharmacy.distanceKm
        self.cachedAt = cachedAt
    }
}

enum NearestPharmacyWidgetStore {
    private static let key = "nobetcim.widget.nearestPharmacies"

    static func save(_ pharmacies: [Pharmacy]) {
        guard let defaults = UserDefaults(suiteName: AppConfig.appGroupID) else { return }
        let payloads = pharmacies.prefix(2).map { NearestPharmacyWidgetPayload(pharmacy: $0) }

        if !payloads.isEmpty, let data = try? JSONEncoder().encode(payloads) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }

        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadTimelines(ofKind: "NearestPharmacyWidget")
        #endif
    }

    static func save(_ pharmacy: Pharmacy?) {
        if let pharmacy {
            save([pharmacy])
        } else {
            save([])
        }
    }
}
