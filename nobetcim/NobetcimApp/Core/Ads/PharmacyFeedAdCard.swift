import SwiftUI

/// In-feed ad slot styled like a pharmacy card (same width, similar height).
struct PharmacyFeedAdCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reklam")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            FeedBannerAdView()
                .frame(maxWidth: .infinity)
                .frame(height: 50)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(Color.primary.opacity(0.06))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reklam")
    }
}

#if canImport(GoogleMobileAds)
import GoogleMobileAds
import UIKit

struct FeedBannerAdView: UIViewRepresentable {
    let adUnitID: String

    init(adUnitID: String = AppConfig.bannerAdUnitID) {
        self.adUnitID = adUnitID
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.rootViewController == nil {
            uiView.rootViewController = Self.rootViewController()
        }
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
}
#else
struct FeedBannerAdView: View {
    var body: some View {
        Text("Reklam alanı")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
    }
}
#endif
