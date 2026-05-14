import SwiftUI

struct TermsView: View {
    var body: some View {
        LegalTextView(
            title: "Kullanım Koşulları",
            paragraphs: [
                "Nöbetçim bilgilendirme amaçlı bir sağlık hizmeti yardımcısıdır.",
                "Eczane nöbet bilgileri resmi veya üçüncü taraf kaynaklardan sağlanabilir ve değişiklik gösterebilir.",
                "Gitmeden önce eczane ile iletişime geçmeniz önerilir."
            ]
        )
    }
}
