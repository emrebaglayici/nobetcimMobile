import MapKit
import SwiftUI

struct PharmacyMapView: View {
    let pharmacies: [Pharmacy]
    var notaries: [Pharmacy] = []
    var showsBanner = AppConfig.adsEnabled

    @State private var selectedPlaceID: String?
    @State private var position: MapCameraPosition = .automatic
    @State private var filter: MapPlaceFilter = .all

    private var allPlaces: [MapPlaceItem] {
        pharmacies.map { MapPlaceItem(place: $0, kind: .pharmacy) }
            + notaries.map { MapPlaceItem(place: $0, kind: .notary) }
    }

    private var visiblePlaces: [MapPlaceItem] {
        allPlaces.filter { item in
            switch filter {
            case .all: true
            case .pharmacies: item.kind == .pharmacy
            case .notaries: item.kind == .notary
            }
        }
    }

    private var selectedPlace: MapPlaceItem? {
        visiblePlaces.first { $0.id == selectedPlaceID }
    }

    /// Harita altı banner — yükseklik adaptive banner boyutundan gelir.
    var body: some View {
        Map(position: $position, selection: $selectedPlaceID) {
            UserAnnotation()
            ForEach(visiblePlaces) { item in
                if let coordinate = item.place.coordinate {
                    Marker(item.place.displayName, systemImage: item.kind.systemImage, coordinate: coordinate)
                        .tint(item.kind.color)
                        .tag(item.id)
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
        .safeAreaInset(edge: .top, spacing: 0) {
            filterBar
                .padding(.horizontal)
                .padding(.top, 8)
        }
        .navigationTitle("Harita")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: allPlaces) {
            selectedPlaceID = nil
            updateCamera()
        }
        .onChange(of: filter) {
            selectedPlaceID = nil
            updateCamera()
        }
        .onAppear {
            updateCamera()
        }
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            ForEach(MapPlaceFilter.allCases) { item in
                Button {
                    withAnimation(.snappy) {
                        filter = item
                    }
                } label: {
                    Label(item.title, systemImage: filter == item ? "checkmark.circle.fill" : item.systemImage)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(filter == item ? item.color : .primary)
                        .background((filter == item ? item.color.opacity(0.12) : Color(.systemBackground)), in: Capsule())
                        .overlay {
                            Capsule()
                                .stroke(filter == item ? item.color.opacity(0.45) : Color.primary.opacity(0.08))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule())
    }

    @ViewBuilder
    private var mapBottomOverlay: some View {
        VStack(spacing: 12) {
            if visiblePlaces.isEmpty {
                EmptyStateView(
                    title: "Haritada sonuç yok",
                    message: "Önce arama yaparak haritada konumları görebilirsiniz.",
                    systemImage: "map",
                    tint: filter == .notaries ? AppTheme.notary : AppTheme.primary
                )
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
                .padding(.horizontal)
            }

            if let selectedPlace {
                selectedPreview(selectedPlace)
                    .padding(.horizontal)
            }

            if showsBanner {
                BannerAdView()
                    .frame(maxWidth: .infinity)
                    .clipped()
            }
        }
        .padding(.bottom, 8)
    }

    private func selectedPreview(_ item: MapPlaceItem) -> some View {
        let place = item.place
        let status = OperatingSchedule.status(kind: item.kind)
        let statusColor: Color = status.isClosed ? .secondary : item.kind.color
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: item.kind.systemImage)
                    .foregroundStyle(item.kind.color)
                Text(place.displayName)
                    .font(.headline)
                Spacer(minLength: 0)
                Label(status.title, systemImage: status.isClosed ? "xmark.circle.fill" : "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }
            Text(place.address)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack {
                Button {
                    AppActions.openAppleMaps(for: place)
                } label: {
                    Label("Yol Tarifi Al", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(item.kind.color)

                NavigationLink {
                    PharmacyDetailView(pharmacy: place, kind: item.kind)
                } label: {
                    Text("Detay")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(item.kind.color)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private func updateCamera() {
        let coordinates = visiblePlaces.compactMap(\.place.coordinate)
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

enum MapPlaceFilter: CaseIterable, Identifiable {
    case all
    case pharmacies
    case notaries

    var id: String { title }

    var title: String {
        switch self {
        case .all: "Hepsi"
        case .pharmacies: "Eczaneler"
        case .notaries: "Noterler"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "square.stack.3d.up.fill"
        case .pharmacies: MapPlaceKind.pharmacy.systemImage
        case .notaries: MapPlaceKind.notary.systemImage
        }
    }

    var color: Color {
        switch self {
        case .all, .pharmacies: AppTheme.primary
        case .notaries: AppTheme.notary
        }
    }
}

enum MapPlaceKind: Hashable {
    case pharmacy
    case notary

    var title: String {
        switch self {
        case .pharmacy: "Eczane"
        case .notary: "Noter"
        }
    }

    var systemImage: String {
        switch self {
        case .pharmacy: "cross.case.fill"
        case .notary: "doc.text.fill"
        }
    }

    var color: Color {
        switch self {
        case .pharmacy: AppTheme.primary
        case .notary: AppTheme.notary
        }
    }

    var callActionTitle: String {
        switch self {
        case .pharmacy: "Eczaneyi Ara"
        case .notary: "Noteri Ara"
        }
    }
}

private struct MapPlaceItem: Identifiable, Hashable {
    let place: Pharmacy
    let kind: MapPlaceKind

    var id: String { "\(kind.title)-\(place.id)" }
}

#Preview {
    NavigationStack {
        PharmacyMapView(pharmacies: Pharmacy.previews, notaries: Pharmacy.previews)
    }
}
