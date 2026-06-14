import CoreLocation
import Foundation
import UIKit

/// Widget önbelleğini konuma göre günceller (uygulama arka planda olsa bile).
enum WidgetLocationSyncService {
    @discardableResult
    static func sync(at location: CLLocation, forceRefresh: Bool = false) async -> [Pharmacy]? {
        guard forceRefresh || NearestPharmacyWidgetStore.shouldRefresh(for: location.coordinate) else {
            return nil
        }

        let bgTask = await MainActor.run {
            UIApplication.shared.beginBackgroundTask(withName: "WidgetLocationSync")
        }

        defer {
            Task { @MainActor in
                guard bgTask != .invalid else { return }
                UIApplication.shared.endBackgroundTask(bgTask)
            }
        }

        do {
            let repository = PharmacyRepository()
            let results = try await repository.fetchNearby(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                forceRefresh: forceRefresh
            )
            return results
        } catch {
            #if DEBUG
            print("WidgetLocationSyncService failed:", error)
            #endif
            return nil
        }
    }
}
