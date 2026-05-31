import SwiftUI

/// Liste içi reklam satırı — eczane kartlarıyla aynı genişlik ve köşe, ek etiket/arka plan yok.
struct PharmacyFeedAdCard: View {
    let slotID: String

    private var bannerWidth: CGFloat {
        AdaptiveBannerLayout.feedBannerWidth()
    }

    private var bannerHeight: CGFloat {
        AdaptiveBannerLayout.feedHeight(forWidth: bannerWidth)
    }

    var body: some View {
        AdaptiveBannerAdView(width: bannerWidth, slotID: slotID)
            .frame(width: bannerWidth, height: bannerHeight)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(Color.primary.opacity(0.06))
            }
            .accessibilityLabel("Reklam")
    }
}
