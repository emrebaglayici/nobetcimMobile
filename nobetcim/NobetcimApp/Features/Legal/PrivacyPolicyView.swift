import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        LegalTextView(
            title: "Gizlilik Politikası",
            paragraphs: [
                "Nöbetçim, nöbetçi eczaneleri göstermek için konum bilginizi yalnızca arama sırasında kullanır.",
                "Konum veriniz hesabınıza bağlanmaz ve bu uygulama içinde kullanıcı hesabı oluşturulmaz.",
                "Reklam ve ölçüm teknolojileri için gerekli izin ve rıza akışları üretim sürümünde UMP üzerinden yönetilmelidir."
            ]
        )
    }
}
