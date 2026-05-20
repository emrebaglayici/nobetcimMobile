import MapKit
import SwiftUI

struct PharmacyMapView: View {
    let pharmacies: [Pharmacy]
    var showsBanner = true

    @State private var selectedPharmacyID: Pharmacy.ID?
    @State private var position: MapCameraPosition = .automatic

    private var selectedPharmacy: Pharmacy? {
        pharmacies.first { $0.id == selectedPharmacyID }
    }

    /// GAD banner’a sabit yükseklik şart; ZStack’te `infinity` proposal WebView’ı şişirip haritayı kapatabiliyor.
    private var mapBannerHeight: CGFloat { 50 }

    var body: some View {
        Map(position: $position, selection: $selectedPharmacyID) {
            UserAnnotation()
            ForEach(pharmacies) { pharmacy in
                if let coordinate = pharmacy.coordinate {
                    Marker(pharmacy.displayName, systemImage: "cross.case.fill", coordinate: coordinate)
                        .tint(AppTheme.primary)
                        .tag(pharmacy.id)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            mapBottomOverlay
        }
        .navigationTitle("Harita")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: pharmacies) {
            updateCamera()
        }
        .onAppear {
            updateCamera()
        }
    }

    @ViewBuilder
    private var mapBottomOverlay: some View {
        VStack(spacing: 12) {
            if pharmacies.isEmpty {
                EmptyStateView(
                    title: "Haritada sonuç yok",
                    message: "Önce arama yaparak haritada konumları görebilirsiniz.",
                    systemImage: "map"
                )
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .padding(.horizontal)
            }

            if let selectedPharmacy {
                selectedPreview(selectedPharmacy)
                    .padding(.horizontal)
            }

            if showsBanner {
                BannerAdView()
                    .frame(height: mapBannerHeight)
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
        }
        .padding(.bottom, 8)
    }

    private func selectedPreview(_ pharmacy: Pharmacy) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(pharmacy.displayName)
                .font(.headline)
            Text(pharmacy.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Button {
                    AppActions.openAppleMaps(for: pharmacy)
                } label: {
                    Label("Yol Tarifi Al", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.directions)

                NavigationLink {
                    PharmacyDetailView(pharmacy: pharmacy)
                } label: {
                    Text("Detay")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private func updateCamera() {
        let coordinates = pharmacies.compactMap(\.coordinate)
        guard !coordinates.isEmpty else {
            position = .automatic
            return
        }

        if coordinates.count == 1, let coordinate = coordinates.first {
            position = .region(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.035, longitudeDelta: 0.035)))
        } else {
            position = .automatic
        }
    }
}

#Preview {
    NavigationStack {
        PharmacyMapView(pharmacies: Pharmacy.previews)
    }
}
