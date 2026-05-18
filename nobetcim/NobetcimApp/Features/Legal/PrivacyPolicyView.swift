import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        LegalTextView(
            title: "Gizlilik Politikası",
            lastUpdated: "Son güncelleme: 28 Mart 2026",
            sections: LegalContent.privacyPolicySections
        )
    }
}
