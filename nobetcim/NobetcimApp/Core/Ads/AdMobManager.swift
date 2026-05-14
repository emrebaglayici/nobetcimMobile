import Foundation

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

final class AdMobManager {
    static let shared = AdMobManager()
    private init() {}

    func configure() {
        #if canImport(GoogleMobileAds)
        MobileAds.shared.start()
        #endif
    }
}
