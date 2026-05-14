import SwiftUI

struct PharmacyListView: View {
    let pharmacies: [Pharmacy]
    let isLoading: Bool
    let errorMessage: String?
    let hasSearched: Bool
    let retry: () -> Void

    var body: some View {
        LazyVStack(spacing: 14) {
            if isLoading {
                LoadingStateView()
            } else if let errorMessage {
                ErrorStateView(message: errorMessage, retry: retry)
            } else if pharmacies.isEmpty && hasSearched {
                EmptyStateView(
                    title: "Sonuç bulunamadı",
                    message: "Farklı bir il veya ilçe seçerek tekrar deneyin.",
                    systemImage: "cross.case"
                )
            } else if pharmacies.isEmpty {
                EmptyStateView(
                    title: "Arama yapın",
                    message: "Konumunuza göre veya il / ilçe seçerek nöbetçi eczaneleri listeleyin.",
                    systemImage: "cross.case.fill"
                )
            } else {
                ForEach(Array(pharmacies.enumerated()), id: \.element.id) { index, pharmacy in
                    PharmacyCardView(pharmacy: pharmacy)
                    if index > 0, (index + 1) % 6 == 0 {
                        NativeAdPlaceholderView()
                            .hidden()
                    }
                }
            }
        }
    }
}

private struct NativeAdPlaceholderView: View {
    var body: some View {
        EmptyView()
    }
}

#Preview {
    ScrollView {
        PharmacyListView(pharmacies: Pharmacy.previews, isLoading: false, errorMessage: nil, hasSearched: true, retry: {})
            .padding()
    }
    .environmentObject(FavoritesStore())
}
