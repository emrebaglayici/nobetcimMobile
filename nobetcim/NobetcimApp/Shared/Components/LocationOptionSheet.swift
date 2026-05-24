import SwiftUI

/// İl / ilçe seçimi için liste + arama (menü picker ScrollView içinde bozuluyordu).
struct LocationOptionSheet: View {
    let title: String
    let options: [String]
    var includesAllDistrictsOption = false
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filteredOptions: [String] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return options }
        return options.filter { $0.localizedCaseInsensitiveContains(trimmed) }
    }

    var body: some View {
        NavigationStack {
            List {
                if includesAllDistrictsOption {
                    optionRow(title: "Tüm ilçeler", isSelected: selection.isEmpty) {
                        selection = ""
                        dismiss()
                    }
                }

                if options.isEmpty {
                    Text("Liste yüklenemedi. İnternet bağlantınızı kontrol edip tekrar deneyin.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if filteredOptions.isEmpty {
                    Text("Sonuç bulunamadı")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredOptions, id: \.self) { option in
                        optionRow(title: option, isSelected: selection == option) {
                            selection = option
                            dismiss()
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Ara")
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }

    private func optionRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(AppTheme.primary)
                        .font(.body.weight(.semibold))
                }
            }
        }
    }
}

struct LocationPickerRow: View {
    let label: String
    let value: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}
