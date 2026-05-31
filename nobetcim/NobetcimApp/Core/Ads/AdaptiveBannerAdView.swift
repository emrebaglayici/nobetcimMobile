import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
import UIKit

enum AdaptiveBannerLayout {
    /// Liste satırı genişliği (ScrollView yatay padding).
    static let feedHorizontalInset: CGFloat = 32
    /// Eczane kartının yaklaşık yarısı yükseklik.
    static let feedMaxHeight: CGFloat = 110

    static func feedBannerWidth(screenWidth: CGFloat = UIScreen.main.bounds.width) -> CGFloat {
        max(screenWidth - feedHorizontalInset, 320)
    }

    static func feedHeight(forWidth width: CGFloat) -> CGFloat {
        inlineAdaptiveSize(width: width, maxHeight: feedMaxHeight).size.height
    }

    static func inlineAdaptiveSize(width: CGFloat, maxHeight: CGFloat) -> AdSize {
        inlineAdaptiveBanner(width: width, maxHeight: maxHeight)
    }

    static func height(forWidth width: CGFloat) -> CGFloat {
        currentOrientationAnchoredAdaptiveBanner(width: width).size.height
    }
}

/// Tam genişlikte inline adaptive banner (liste içi).
struct AdaptiveBannerAdView: UIViewRepresentable {
    let adUnitID: String
    var width: CGFloat?
    var maxHeight: CGFloat?
    let slotID: String

    init(
        adUnitID: String = AppConfig.bannerAdUnitID,
        width: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        slotID: String = UUID().uuidString
    ) {
        self.adUnitID = adUnitID
        self.width = width
        self.maxHeight = maxHeight
        self.slotID = slotID
    }

    func makeUIView(context: Context) -> AdaptiveBannerHostView {
        let view = AdaptiveBannerHostView()
        view.configure(adUnitID: adUnitID, slotID: slotID, maxHeight: maxHeight)
        return view
    }

    func updateUIView(_ uiView: AdaptiveBannerHostView, context: Context) {
        uiView.configure(adUnitID: adUnitID, slotID: slotID, maxHeight: maxHeight)
        if let width {
            uiView.preferredWidth = width
            uiView.setNeedsLayout()
        }
    }
}

final class AdaptiveBannerHostView: UIView {
    private var adUnitID: String = AppConfig.bannerAdUnitID
    private var slotID: String = ""
    private var maxHeight: CGFloat = AdaptiveBannerLayout.feedMaxHeight

    var preferredWidth: CGFloat?

    private var bannerView: BannerView?
    private var loadedWidth: CGFloat = 0

    func configure(adUnitID: String, slotID: String, maxHeight: CGFloat?) {
        self.adUnitID = adUnitID
        self.slotID = slotID
        if let maxHeight {
            self.maxHeight = maxHeight
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = preferredWidth ?? bounds.width
        guard width > 0 else { return }
        guard abs(width - loadedWidth) > 0.5 else { return }
        loadedWidth = width
        installBanner(width: width)
    }

    private func installBanner(width: CGFloat) {
        bannerView?.removeFromSuperview()

        let adSize = AdaptiveBannerLayout.inlineAdaptiveSize(width: width, maxHeight: maxHeight)
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = Self.rootViewController()
        banner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(banner)

        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: trailingAnchor),
            banner.topAnchor.constraint(equalTo: topAnchor),
            banner.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        banner.load(Request())
        bannerView = banner
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
enum AdaptiveBannerLayout {
    static let feedHorizontalInset: CGFloat = 32
    static let feedMaxHeight: CGFloat = 110

    static func feedBannerWidth(screenWidth: CGFloat = 375) -> CGFloat {
        max(screenWidth - feedHorizontalInset, 320)
    }

    static func feedHeight(forWidth width: CGFloat) -> CGFloat { 90 }
    static func height(forWidth width: CGFloat) -> CGFloat { 50 }
}

struct AdaptiveBannerAdView: View {
    let adUnitID: String
    var width: CGFloat?
    var maxHeight: CGFloat?
    let slotID: String

    init(
        adUnitID: String = AppConfig.bannerAdUnitID,
        width: CGFloat? = nil,
        maxHeight: CGFloat? = nil,
        slotID: String = UUID().uuidString
    ) {
        self.adUnitID = adUnitID
        self.width = width
        self.maxHeight = maxHeight
        self.slotID = slotID
    }

    var body: some View {
        Color.clear
            .frame(height: AdaptiveBannerLayout.feedHeight(forWidth: width ?? 320))
    }
}
#endif
