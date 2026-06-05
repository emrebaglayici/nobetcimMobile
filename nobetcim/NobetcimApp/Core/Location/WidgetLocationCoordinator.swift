import Combine
import CoreLocation
import Foundation

/// Widget için arka plan konum izlemesini uygulama genelinde yönetir.
@MainActor
final class WidgetLocationCoordinator: ObservableObject {
    private weak var locationManager: LocationManager?

    func attach(to locationManager: LocationManager) {
        self.locationManager = locationManager
        locationManager.onSignificantLocationChange = { [weak self] location in
            Task { @MainActor in
                await self?.handleLocationUpdate(location)
            }
        }
        refreshMonitoring()
    }

    func refreshMonitoring() {
        guard let locationManager else { return }
        locationManager.setSignificantLocationMonitoringEnabled(locationManager.isAuthorized)
    }

    func syncNow(forceRefresh: Bool = false) async {
        guard let locationManager, locationManager.isAuthorized else { return }

        do {
            let location = try await locationManager.requestLocation(preferCached: !forceRefresh)
            await handleLocationUpdate(location, forceRefresh: forceRefresh)
        } catch {
            #if DEBUG
            print("WidgetLocationCoordinator syncNow failed:", error)
            #endif
        }
    }

    private func handleLocationUpdate(_ location: CLLocation, forceRefresh: Bool = false) async {
        await WidgetLocationSyncService.sync(at: location, forceRefresh: forceRefresh)
    }
}
