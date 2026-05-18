import SwiftUI

struct TermsView: View {
    var body: some View {
        LegalTextView(
            title: "Kullanım Koşulları",
            lastUpdated: "Son güncelleme: 3 Nisan 2026",
            sections: LegalContent.termsSections
        )
    }
}
