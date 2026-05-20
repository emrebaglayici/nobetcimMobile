import MapKit
import SwiftUI

struct PharmacyDetailView: View {
    let pharmacy: Pharmacy
    @State private var showsPhoneAlert = false
    @State private var showsDirectionsAlert = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    header

                    VStack(alignment: .leading, spacing: 16) {
                        mapPreview
                        infoSection
                        actions
                        warning
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: AppTheme.contentMaxWidth)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Eczane Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Telefon numarası bulunamadı.", isPresented: $showsPhoneAlert) {
            Button("Tamam", role: .cancel) {}
        }
        .alert("Yol tarifi için konum bilgisi eksik.", isPresented: $showsDirectionsAlert) {
            Button("Tamam", role: .cancel) {}
        }
    }

    private var header: some View {
        ZStack {
            AppTheme.primary.opacity(0.10)
                .ignoresSafeArea(edges: .horizontal)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.title3)
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 40, height: 40)
                    .background(Color(.systemBackground).opacity(0.92), in: Circle())

                VStack(alignment: .leading, spacing: 6) {
                    Text(pharmacy.displayName)
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(pharmacy.displayLocationLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    DetailBadge(text: "Bugün Nöbetçi", systemImage: "checkmark.seal.fill", color: AppTheme.primary)
                }

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: AppTheme.contentMaxWidth, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var mapPreview: some View {
        if let coordinate = pharmacy.coordinate {
            DetailCard {
                VStack(spacing: 0) {
                    Map {
                        Marker(pharmacy.displayName, coordinate: coordinate)
                    }
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .allowsHitTesting(true)

                    Divider()

                    Button {
                        AppActions.openAppleMaps(for: pharmacy)
                    } label: {
                        Label("Yol Tarifi", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.directions)
                    .padding(12)
                }
            }
        }
    }

    private var infoSection: some View {
        DetailCard {
            VStack(alignment: .leading, spacing: 14) {
                InfoRow(title: "Adres", value: pharmacy.displayAddress, systemImage: "mappin.and.ellipse")
                InfoRow(title: "Telefon", value: pharmacy.phone ?? "Telefon numarası bulunamadı.", systemImage: "phone")
                InfoRow(title: "Konum", value: pharmacy.displayLocationLine, systemImage: "building.2")
            }
            .padding(16)
        }
    }

    private var actions: some View {
        DetailCard {
            VStack(spacing: 10) {
                Button {
                    guard pharmacy.phone?.isEmpty == false else {
                        showsPhoneAlert = true
                        return
                    }
                    AppActions.call(pharmacy.phone)
                } label: {
                    Label("Eczaneyi Ara", systemImage: "phone.fill")
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
                    Label("Apple Haritalar ile Yol Tarifi", systemImage: "map.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.directions)

                Button {
                    guard pharmacy.coordinate != nil else {
                        showsDirectionsAlert = true
                        return
                    }
                    AppActions.openGoogleMaps(for: pharmacy)
                } label: {
                    Label("Google Haritalar ile Aç", systemImage: "globe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(16)
        }
    }

    private var warning: some View {
        Label(
            "Bilgiler kaynak verilerden alınır. Gitmeden önce işletme ile iletişime geçmeniz önerilir.",
            systemImage: "info.circle.fill"
        )
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.warning.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct DetailCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                    .stroke(Color.primary.opacity(0.06))
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}

private struct InfoRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(AppTheme.primary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct DetailBadge: View {
    let text: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }
}

#Preview {
    NavigationStack {
        PharmacyDetailView(pharmacy: Pharmacy.previews[0])
    }
}
