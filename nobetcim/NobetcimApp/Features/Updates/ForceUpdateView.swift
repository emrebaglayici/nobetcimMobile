import SwiftUI

struct ForceUpdateView: View {
    let message: String
    let appStoreURL: URL

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.primary)
                .accessibilityHidden(true)

            VStack(spacing: 10) {
                Text("Güncelleme Gerekli")
                    .font(.title2.bold())

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                UIApplication.shared.open(appStoreURL)
            } label: {
                Text("App Store'da Güncelle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)

            Text("Mevcut sürüm: \(AppConfig.appVersion)")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(28)
        .frame(maxWidth: AppTheme.contentMaxWidth)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    ForceUpdateView(
        message: "Devam etmek için lütfen uygulamayı güncelleyin.",
        appStoreURL: URL(string: AppUpdatePolicy.fallbackAppStoreURL)!
    )
}
