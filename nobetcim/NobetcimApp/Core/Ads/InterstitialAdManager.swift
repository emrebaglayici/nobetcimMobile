import Foundation
import SwiftUI
import Combine
import UIKit

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class InterstitialAdManager: ObservableObject {
    private var engagementCount = 0
    private var lastPresentedAt: Date?
    private let minimumInterval: TimeInterval = 90

    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    #endif

    func load() {
        guard AppConfig.adsEnabled else { return }
        #if canImport(GoogleMobileAds)
        InterstitialAd.load(with: AppConfig.interstitialAdUnitID, request: Request()) { [weak self] ad, _ in
            guard let ad else { return }
            Task { @MainActor [weak self, ad] in
                guard let self else { return }
                self.interstitial = ad
            }
        }
        #endif
    }

    func recordSuccessfulSearch() {
        guard AppConfig.adsEnabled else { return }
        engagementCount += 1
        if engagementCount % 2 == 0 {
            presentIfReady()
        }
    }

    func recordTabChange() {
        guard AppConfig.adsEnabled else { return }
        engagementCount += 1
        if engagementCount % 3 == 0 {
            presentIfReady()
        }
    }

    func recordAppBecameActive() {
        guard AppConfig.adsEnabled else { return }
        engagementCount += 1
        if engagementCount % 5 == 0 {
            presentIfReady()
        }
    }

    private func presentIfReady() {
        guard canPresentNow else { return }

        #if canImport(GoogleMobileAds)
        guard let root = Self.topViewController(),
              let ad = interstitial else {
            load()
            return
        }
        ad.present(from: root)
        self.interstitial = nil
        lastPresentedAt = Date()
        load()
        #endif
    }

    private var canPresentNow: Bool {
        guard let lastPresentedAt else { return true }
        return Date().timeIntervalSince(lastPresentedAt) >= minimumInterval
    }

    private static func topViewController() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            return nil
        }
        return topPresenter(from: root)
    }

    private static func topPresenter(from controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController {
            return topPresenter(from: presented)
        }
        if let navigation = controller as? UINavigationController, let visible = navigation.visibleViewController {
            return topPresenter(from: visible)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topPresenter(from: selected)
        }
        return controller
    }
}
