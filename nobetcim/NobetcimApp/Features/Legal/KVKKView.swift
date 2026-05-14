import SwiftUI

struct KVKKView: View {
    var body: some View {
        LegalTextView(
            title: "KVKK",
            paragraphs: [
                "Kişisel veriler, hizmetin sunulması için gerekli olan en düşük kapsamda işlenmelidir.",
                "Konum izni isteğe bağlıdır. İzin verilmediğinde il ve ilçe seçimi ile arama yapılabilir.",
                "Üretim öncesinde veri sorumlusu bilgileri, saklama süreleri ve başvuru kanalları güncellenmelidir."
            ]
        )
    }
}
