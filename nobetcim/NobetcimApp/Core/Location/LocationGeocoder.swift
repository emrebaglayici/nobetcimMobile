import CoreLocation
import Foundation

enum LocationGeocoder {
    /// Konumdan il adını çözer; yalnızca `TurkeyLocationCatalog` içindeki iller döner.
    static func resolveCity(from location: CLLocation) async throws -> String? {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.reverseGeocodeLocation(location)
        guard let placemark = placemarks.first else { return nil }

        let candidates = [
            placemark.administrativeArea,
            placemark.subAdministrativeArea,
        ]
        .compactMap { $0?.normalizedProvinceCandidate }
        .filter { !$0.isEmpty }

        for candidate in candidates {
            if let entry = TurkeyLocationCatalog.entry(for: candidate) {
                return entry.city
            }
        }
        return nil
    }
}

private extension String {
    var normalizedProvinceCandidate: String {
        var value = trimmingCharacters(in: .whitespacesAndNewlines)
        for suffix in [" Province", " İli", " ili", " province"] {
            if value.hasSuffix(suffix) {
                value = String(value.dropLast(suffix.count))
            }
        }
        return value.localizedTitleCasedTurkish
    }
}
