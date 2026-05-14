import Foundation
import SwiftUI
import Combine

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class InterstitialAdManager: ObservableObject {
    private var successfulSearchCount = 0

    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    #endif

    func load() {
        #if canImport(GoogleMobileAds)
        InterstitialAd.load(with: AppConfig.interstitialAdUnitID, request: Request()) { [weak self] ad, _ in
            self?.interstitial = ad
        }
        #endif
    }

    func recordSuccessfulSearch() {
        successfulSearchCount += 1
    }

    func showIfEligible() {
        guard successfulSearchCount >= 3, successfulSearchCount % 3 == 0 else { return }
        #if canImport(GoogleMobileAds)
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?
            .rootViewController,
              let interstitial else {
            load()
            return
        }
        interstitial.present(from: root)
        self.interstitial = nil
        load()
        #endif
    }
}
