import SwiftUI

enum PharmacyFeedItem: Identifiable {
    case pharmacy(Pharmacy)
    case advertisement(id: String)

    var id: String {
        switch self {
        case .pharmacy(let pharmacy):
            pharmacy.id
        case .advertisement(let id):
            id
        }
    }
}

struct PharmacyListView: View {
    let pharmacies: [Pharmacy]
    let isLoading: Bool
    let errorMessage: String?
    let hasSearched: Bool
    let retry: () -> Void

    private var feedItems: [PharmacyFeedItem] {
        Self.makeFeed(from: pharmacies)
    }

    var body: some View {
        LazyVStack(spacing: 14) {
            if isLoading {
                LoadingStateView(message: "En yakın eczane bulunuyor…")
            } else if pharmacies.isEmpty, let errorMessage {
                ErrorStateView(message: errorMessage, retry: retry)
            } else if pharmacies.isEmpty, hasSearched {
                EmptyStateView(
                    title: "Sonuç bulunamadı",
                    message: "Farklı bir il veya ilçe seçerek tekrar deneyin.",
                    systemImage: "cross.case"
                )
            } else if pharmacies.isEmpty {
                EmptyStateView(
                    title: "Arama yapın",
                    message: "Konumunuza göre veya il / ilçe seçerek arama yapın. Şu an nöbetçi eczaneler listelenir.",
                    systemImage: "cross.case.fill"
                )
            } else {
                if let errorMessage {
                    ListNoticeBanner(message: errorMessage)
                }

                ForEach(feedItems) { item in
                    switch item {
                    case .pharmacy(let pharmacy):
                        PharmacyCardView(pharmacy: pharmacy)
                    case .advertisement(let id):
                        PharmacyFeedAdCard(slotID: id)
                    }
                }
            }
        }
    }

    /// Inserts one ad card after every two pharmacy entries when ads are enabled.
    static func makeFeed(from pharmacies: [Pharmacy]) -> [PharmacyFeedItem] {
        var items: [PharmacyFeedItem] = []
        for (index, pharmacy) in pharmacies.enumerated() {
            items.append(.pharmacy(pharmacy))
            if AppConfig.adsEnabled, (index + 1) % 2 == 0 {
                items.append(.advertisement(id: "feed-ad-\(index / 2)"))
            }
        }
        return items
    }
}

private struct ListNoticeBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.warning.opacity(0.14), in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ScrollView {
        PharmacyListView(pharmacies: Pharmacy.previews, isLoading: false, errorMessage: nil, hasSearched: true, retry: {})
            .padding()
    }
}
