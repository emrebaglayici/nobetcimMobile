import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section {
                CategorySelectionView()
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section("Yasal") {
                NavigationLink("Gizlilik Politikası") {
                    PrivacyPolicyView()
                }
                NavigationLink("Kullanım Koşulları") {
                    TermsView()
                }
                NavigationLink("KVKK") {
                    KVKKView()
                }
            }

            Section("Uygulama") {
                LabeledContent("Sürüm", value: AppConfig.appVersion)
                LabeledContent("İletişim", value: AppConfig.supportEmail)
            }

            Section("Bilgilendirme") {
                Text("Gösterilen kayıtlar kaynak verilere dayanır; adres, mesafe ve iletişim bilgileri hatalı veya güncel olmayabilir. Gitmeden önce ilgili işletmeyi aramanız önerilir. Tıbbi acil durumlarda 112 ve yetkili kurumlara başvurun.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Daha Fazla")
        .tint(AppTheme.primary)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
