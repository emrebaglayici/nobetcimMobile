import SwiftUI

struct PharmacyCardView: View {
    let pharmacy: Pharmacy
    @State private var showsPhoneAlert = false
    @State private var showsDirectionsAlert = false

    var body: some View {
        NavigationLink {
            PharmacyDetailView(pharmacy: pharmacy)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "cross.case.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 40, height: 40)
                        .background(AppTheme.primary.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pharmacy.displayName)
                            .font(.headline)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                        Text("\(pharmacy.district) / \(pharmacy.city)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }

                Text(pharmacy.address)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Badge(text: "Bugün Nöbetçi", systemImage: "checkmark.seal.fill", color: AppTheme.primary)
                    if let distance = pharmacy.distanceKm {
                        Badge(text: String(format: "%.1f km", distance), systemImage: "location.fill", color: .blue)
                    }
                }

                HStack(spacing: 10) {
                    Button {
                        guard pharmacy.phone?.isEmpty == false else {
                            showsPhoneAlert = true
                            return
                        }
                        AppActions.call(pharmacy.phone)
                    } label: {
                        Label("Ara", systemImage: "phone.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.call)

                    Button {
                        guard pharmacy.coordinate != nil else {
                            showsDirectionsAlert = true
                            return
                        }
                        AppActions.openAppleMaps(for: pharmacy)
                    } label: {
                        Label("Yol Tarifi", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.directions)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(Color.primary.opacity(0.06))
            }
        }
        .buttonStyle(.plain)
        .alert("Telefon numarası bulunamadı.", isPresented: $showsPhoneAlert) {
            Button("Tamam", role: .cancel) {}
        }
        .alert("Yol tarifi için konum bilgisi eksik.", isPresented: $showsDirectionsAlert) {
            Button("Tamam", role: .cancel) {}
        }
    }
}

private struct Badge: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.bold())
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        PharmacyCardView(pharmacy: Pharmacy.previews[0])
            .padding()
    }
}
