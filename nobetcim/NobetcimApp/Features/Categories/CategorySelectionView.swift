import SwiftUI

struct CategorySelectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Özellikler")
                .font(.headline)

            ForEach(DutyCategory.allCases) { category in
                HStack {
                    Image(systemName: category.systemImage)
                        .foregroundStyle(category.isAvailable ? AppTheme.primary : .secondary)
                        .frame(width: 28)
                    Text(category.title)
                    Spacer()
                    if category.isAvailable {
                        Text("Aktif")
                            .font(.caption.bold())
                            .foregroundStyle(AppTheme.primary)
                    } else {
                        Text("Yakında")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                .opacity(category.isAvailable ? 1 : 0.62)
            }

            Text("Nöbetçim Cebinde, yerel hizmetleri tek çatı altında sunmayı hedefler; yeni kategoriler güncellemelerle eklenecek.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
