import SwiftUI

struct CategorySelectionView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hizmetler")
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
        }
    }
}
