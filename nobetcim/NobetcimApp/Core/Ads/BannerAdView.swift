import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
import UIKit

struct BannerAdView: View {
    let adUnitID: String

    init(adUnitID: String = AppConfig.bannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    var body: some View {
        GeometryReader { proxy in
            let width = max(proxy.size.width, 320)
            AdaptiveBannerAdView(adUnitID: adUnitID, width: width)
                .frame(width: width, height: AdaptiveBannerLayout.height(forWidth: width))
        }
        .frame(height: AdaptiveBannerLayout.height(forWidth: UIScreen.main.bounds.width))
    }
}
#else
struct BannerAdView: View {
    let adUnitID: String

    init(adUnitID: String = AppConfig.bannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    var body: some View {
        Text("Reklam alanı")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .accessibilityHidden(true)
    }
}
#endif
