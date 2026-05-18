import SwiftUI

struct KVKKView: View {
    var body: some View {
        LegalTextView(
            title: "KVKK Aydınlatma Metni",
            lastUpdated: "6698 sayılı Kişisel Verilerin Korunması Kanunu — Son güncelleme: 3 Nisan 2026",
            sections: LegalContent.kvkkSections,
            footer: "Bu metin genel bilgilendirme amaçlıdır; somut uyuşmazlıklarda hukuki danışmanlık alınız."
        )
    }
}
