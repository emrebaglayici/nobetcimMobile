import CoreLocation
import Foundation
import MapKit

struct Pharmacy: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let city: String
    let district: String
    let address: String
    let phone: String?
    let latitude: Double?
    let longitude: Double?
    var distanceKm: Double?
    let date: String?
    let source: String?

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude, let longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var displayName: String {
        name.localizedTitleCasedTurkish
    }

    var displayCity: String {
        city.localizedTitleCasedTurkish
    }

    var displayDistrict: String {
        district.localizedTitleCasedTurkish
    }

    var displayAddress: String {
        address.localizedTitleCasedTurkish
    }

    var displayLocationLine: String {
        [displayDistrict, displayCity]
            .filter { !$0.isEmpty }
            .joined(separator: " / ")
    }

    var mapItem: MKMapItem? {
        guard let coordinate else { return nil }
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = name
        return item
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case ad
        case pharmacyName
        case title
        case city
        case il
        case district
        case ilce
        case address
        case adres
        case phone
        case phoneNumber
        case telefon
        case latitude
        case lat
        case longitude
        case lng
        case lon
        case distanceKm
        case distance
        case mesafe
        case date
        case tarih
        case source
        case konum
    }

    enum LocationCodingKeys: String, CodingKey {
        case lat
        case lng
    }

    init(
        id: String,
        name: String,
        city: String,
        district: String,
        address: String,
        phone: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        distanceKm: Double? = nil,
        date: String? = nil,
        source: String? = nil
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.district = district
        self.address = address
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
        self.distanceKm = distanceKm
        self.date = date
        self.source = source
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = (try container.decodeFirstString(for: [.name, .ad, .pharmacyName, .title]) ?? "Eczane")
            .localizedTitleCasedTurkish
        let city = (try container.decodeFirstString(for: [.city, .il]) ?? "").localizedTitleCasedTurkish
        let district = (try container.decodeFirstString(for: [.district, .ilce]) ?? "").localizedTitleCasedTurkish
        let address = (try container.decodeFirstString(for: [.address, .adres]) ?? "").localizedTitleCasedTurkish
        let phone = try container.decodeFirstString(for: [.phone, .phoneNumber, .telefon])
        var latitude = try container.decodeFirstDouble(for: [.latitude, .lat])
        var longitude = try container.decodeFirstDouble(for: [.longitude, .lng, .lon])
        if let locationContainer = try? container.nestedContainer(keyedBy: LocationCodingKeys.self, forKey: .konum) {
            latitude = latitude ?? locationContainer.decodeFlexibleDouble(forKey: .lat)
            longitude = longitude ?? locationContainer.decodeFlexibleDouble(forKey: .lng)
        }

        self.id = try container.decodeFirstString(for: [.id]) ?? "\(name)-\(city)-\(district)-\(address)".stableID
        self.name = name
        self.city = city
        self.district = district
        self.address = address
        self.phone = phone
        self.latitude = latitude
        self.longitude = longitude
        if let meters = try container.decodeFirstDouble(for: [.mesafe]), meters > 0 {
            self.distanceKm = meters >= 100 ? meters / 1000 : meters
        } else {
            self.distanceKm = try container.decodeFirstDouble(for: [.distanceKm, .distance])
        }
        self.date = try container.decodeFirstString(for: [.date, .tarih])
        self.source = try container.decodeFirstString(for: [.source])
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(city, forKey: .city)
        try container.encode(district, forKey: .district)
        try container.encode(address, forKey: .address)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(latitude, forKey: .latitude)
        try container.encodeIfPresent(longitude, forKey: .longitude)
        try container.encodeIfPresent(distanceKm, forKey: .distanceKm)
        try container.encodeIfPresent(date, forKey: .date)
        try container.encodeIfPresent(source, forKey: .source)
    }
}

private extension KeyedDecodingContainer where Key == Pharmacy.LocationCodingKeys {
    func decodeFlexibleDouble(forKey key: Key) -> Double? {
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return Double(value.replacingOccurrences(of: ",", with: "."))
        }
        return nil
    }
}

extension Pharmacy {
    static let previews: [Pharmacy] = [
        Pharmacy(
            id: "preview-1",
            name: "Şifa Eczanesi",
            city: "İstanbul",
            district: "Kadıköy",
            address: "Caferağa Mah. Moda Cad. No:24 Kadıköy/İstanbul",
            phone: "0216 000 00 01",
            latitude: 40.9875,
            longitude: 29.0277,
            distanceKm: 1.2,
            date: "Bugün",
            source: "Önizleme"
        ),
        Pharmacy(
            id: "preview-2",
            name: "Hayat Eczanesi",
            city: "İstanbul",
            district: "Üsküdar",
            address: "Mimar Sinan Mah. Hakimiyet-i Milliye Cad. No:12 Üsküdar/İstanbul",
            phone: "0216 000 00 02",
            latitude: 41.022,
            longitude: 29.015,
            distanceKm: 3.8,
            date: "Bugün",
            source: "Önizleme"
        )
    ]
}

private extension KeyedDecodingContainer where Key == Pharmacy.CodingKeys {
    func decodeFirstString(for keys: [Key]) throws -> String? {
        for key in keys {
            if let value = try? decodeIfPresent(String.self, forKey: key), !value.isEmpty {
                return value
            }
            if let value = try? decodeIfPresent(Int.self, forKey: key) {
                return String(value)
            }
        }
        return nil
    }

    func decodeFirstDouble(for keys: [Key]) throws -> Double? {
        for key in keys {
            if let value = try? decodeIfPresent(Double.self, forKey: key) {
                return value
            }
            if let value = try? decodeIfPresent(String.self, forKey: key), let double = Double(value.replacingOccurrences(of: ",", with: ".")) {
                return double
            }
        }
        return nil
    }
}

private extension String {
    var stableID: String {
        lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "/", with: "-")
    }
}
