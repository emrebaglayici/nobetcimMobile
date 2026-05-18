import Combine
import CoreLocation
import Foundation

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var errorMessage: String?

    /// Called when continuous monitoring detects a new fix (foreground only).
    var onLocationUpdate: ((CLLocation) -> Void)?

    private let manager = CLLocationManager()
    private var locationWaiters: [CheckedContinuation<CLLocation, Error>] = []
    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?
    private var isContinuousMonitoring = false

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 250
        manager.pausesLocationUpdatesAutomatically = true
    }

    var isAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    func setContinuousMonitoringEnabled(_ enabled: Bool) {
        guard enabled != isContinuousMonitoring else { return }
        isContinuousMonitoring = enabled

        guard isAuthorized else { return }

        if enabled {
            manager.startUpdatingLocation()
        } else if locationWaiters.isEmpty {
            manager.stopUpdatingLocation()
        }
    }

    func requestLocation(preferCached: Bool = false) async throws -> CLLocation {
        errorMessage = nil

        let status = try await requestAuthorizationIfNeeded()

        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            errorMessage = "Konum izni verilmedi."
            throw LocationError.denied
        }

        if preferCached, let cached = cachedLocation(maxAge: 900) {
            return cached
        }

        if let cached = cachedLocation(maxAge: 300) {
            return cached
        }

        return try await requestFreshLocation()
    }

    private func cachedLocation(maxAge: TimeInterval) -> CLLocation? {
        guard let currentLocation, currentLocation.timestamp.timeIntervalSinceNow > -maxAge else {
            return nil
        }
        return currentLocation
    }

    private func requestFreshLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationWaiters.append(continuation)
            manager.requestLocation()
        }
    }

    private func requestAuthorizationIfNeeded() async throws -> CLAuthorizationStatus {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        case .restricted, .denied:
            throw LocationError.denied
        default:
            return authorizationStatus
        }
    }

    private func finishContinuousRequestIfNeeded() {
        if !isContinuousMonitoring, locationWaiters.isEmpty {
            manager.stopUpdatingLocation()
        }
    }

    private func resumeAllWaiters(with result: Result<CLLocation, Error>) {
        let waiters = locationWaiters
        locationWaiters.removeAll()
        for waiter in waiters {
            switch result {
            case .success(let location):
                waiter.resume(returning: location)
            case .failure(let error):
                waiter.resume(throwing: error)
            }
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        authorizationContinuation?.resume(returning: manager.authorizationStatus)
        authorizationContinuation = nil

        if isContinuousMonitoring, isAuthorized {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        if !locationWaiters.isEmpty {
            resumeAllWaiters(with: .success(location))
            finishContinuousRequestIfNeeded()
        }

        if isContinuousMonitoring {
            onLocationUpdate?(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        errorMessage = "Konum bilgisi alınamadı."

        if !locationWaiters.isEmpty {
            if let cached = cachedLocation(maxAge: 900) {
                resumeAllWaiters(with: .success(cached))
            } else {
                resumeAllWaiters(with: .failure(error))
            }
            finishContinuousRequestIfNeeded()
        }
    }
}

enum LocationError: LocalizedError {
    case denied

    var errorDescription: String? {
        "Konum izni verilmedi."
    }
}
