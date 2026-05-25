import CoreLocation
import MapKit

/// Liste km değerleri: Apple Haritalar ile uyumlu araç yolu (MKDirections), tek seferde hesaplanır.
enum PharmacyDistanceCalculator {
    private static let maxConcurrent = 4
    private static let perRequestTimeoutNanoseconds: UInt64 = 1_500_000_000

    static func resolveDistances(_ pharmacies: [Pharmacy], from origin: CLLocation) async -> [Pharmacy] {
        guard !pharmacies.isEmpty else { return pharmacies }

        var distancesByID: [String: Double] = [:]
        for pharmacy in pharmacies {
            guard let coordinate = pharmacy.coordinate else { continue }
            distancesByID[pharmacy.id] = straightLineKm(from: origin.coordinate, to: coordinate)
        }

        let candidates = pharmacies.filter { $0.coordinate != nil }
        let indexed = Array(candidates.enumerated())

        for chunkStart in stride(from: 0, to: indexed.count, by: maxConcurrent) {
            let chunkEnd = min(chunkStart + maxConcurrent, indexed.count)
            let chunk = indexed[chunkStart..<chunkEnd]

            await withTaskGroup(of: (String, Double?).self) { group in
                for (_, pharmacy) in chunk {
                    group.addTask {
                        let km = await drivingDistanceKmWithTimeout(from: origin, to: pharmacy)
                        return (pharmacy.id, km)
                    }
                }

                for await (id, km) in group {
                    if let km {
                        distancesByID[id] = km
                    }
                }
            }
        }

        return pharmacies
            .map { pharmacy -> Pharmacy in
                var copy = pharmacy
                if let km = distancesByID[pharmacy.id] {
                    copy.distanceKm = km
                }
                return copy
            }
            .sorted {
                ($0.distanceKm ?? .greatestFiniteMagnitude) < ($1.distanceKm ?? .greatestFiniteMagnitude)
            }
    }

    private static func drivingDistanceKmWithTimeout(from origin: CLLocation, to pharmacy: Pharmacy) async -> Double? {
        guard let coordinate = pharmacy.coordinate else { return nil }

        return await withTaskGroup(of: Double?.self) { group in
            group.addTask {
                await drivingDistanceKm(from: origin, to: coordinate)
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: perRequestTimeoutNanoseconds)
                return nil
            }

            defer { group.cancelAll() }
            for await value in group {
                if let value { return value }
            }
            return straightLineKm(from: origin.coordinate, to: coordinate)
        }
    }

    private static func drivingDistanceKm(from origin: CLLocation, to coordinate: CLLocationCoordinate2D) async -> Double? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile

        do {
            let response = try await MKDirections(request: request).calculate()
            guard let route = response.routes.min(by: { $0.distance < $1.distance }) else {
                return straightLineKm(from: origin.coordinate, to: coordinate)
            }
            return route.distance / 1000
        } catch {
            return straightLineKm(from: origin.coordinate, to: coordinate)
        }
    }

    private static func straightLineKm(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) -> Double {
        let start = CLLocation(latitude: origin.latitude, longitude: origin.longitude)
        let end = CLLocation(latitude: destination.latitude, longitude: destination.longitude)
        return start.distance(from: end) / 1000
    }
}
