import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var interstitialAdManager: InterstitialAdManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSearchOptionsExpanded = true
    @State private var isCityPickerPresented = false
    @State private var isDistrictPickerPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                searchPanel

                PharmacyListView(
                    pharmacies: viewModel.pharmacies,
                    isLoading: viewModel.isLoading,
                    errorMessage: viewModel.errorMessage,
                    hasSearched: viewModel.hasSearched,
                    retry: { Task { await performSearch(forceRefresh: true) } }
                )
            }
            .padding()
            .frame(maxWidth: AppTheme.contentMaxWidth, alignment: .top)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await performSearch(forceRefresh: true, isPullToRefresh: true)
        }
        .navigationTitle(AppConfig.appName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if AppConfig.adsEnabled {
                interstitialAdManager.load()
            }
            configureLocationMonitoring()
            await viewModel.loadDirectory()
            if !viewModel.hasSearched, viewModel.searchMode == .nearby {
                await performSearch()
            }
        }
        .onChange(of: viewModel.searchMode) {
            configureLocationMonitoring()
            Task {
                switch viewModel.searchMode {
                case .nearby:
                    viewModel.clearResultsForModeChange()
                    await performSearch(forceRefresh: true)
                case .city:
                    viewModel.clearResultsForModeChange()
                    await viewModel.loadDirectory()
                    await viewModel.applyCityFromLocation(locationManager: locationManager)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                locationManager.setContinuousMonitoringEnabled(false)
                return
            }
            configureLocationMonitoring()
            if AppConfig.adsEnabled {
                interstitialAdManager.recordAppBecameActive()
            }
            Task {
                await viewModel.refreshNearbyForWidgetIfNeeded(locationManager: locationManager)
            }
        }
        .sheet(isPresented: $isCityPickerPresented) {
            LocationOptionSheet(
                title: "İl seçin",
                options: viewModel.cities,
                selection: $viewModel.selectedCity
            )
            .onDisappear {
                viewModel.updateDistrictForSelectedCity()
            }
        }
        .sheet(isPresented: $isDistrictPickerPresented) {
            LocationOptionSheet(
                title: "İlçe seçin",
                options: viewModel.districts,
                includesAllDistrictsOption: true,
                selection: $viewModel.selectedDistrict
            )
            .onDisappear {
                guard viewModel.searchMode == .city, !viewModel.cities.isEmpty else { return }
                Task { await performSearch() }
            }
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Button {
                withAnimation(.snappy) {
                    isSearchOptionsExpanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(AppTheme.primary)
                        .frame(width: 30, height: 30)
                        .background(AppTheme.primary.opacity(0.10), in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Arama filtresi")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(searchSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isSearchOptionsExpanded ? 180 : 0))
                }
                .contentShape(Rectangle())
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)

            if isSearchOptionsExpanded {
                VStack(spacing: 10) {
                    Picker("Arama modu", selection: $viewModel.searchMode) {
                        ForEach(SearchMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if viewModel.searchMode == .city {
                        VStack(spacing: 8) {
                            LocationPickerRow(
                                label: "İl",
                                value: viewModel.cities.isEmpty ? "Yükleniyor…" : viewModel.selectedCity,
                                isLoading: viewModel.cities.isEmpty
                            ) {
                                isCityPickerPresented = true
                            }

                            LocationPickerRow(
                                label: "İlçe",
                                value: districtPickerLabel,
                                isLoading: viewModel.isLoadingDirectory && viewModel.districts.isEmpty
                            ) {
                                isDistrictPickerPresented = true
                            }
                        }
                    }
                }
            }

            Button {
                Task { await performSearch() }
            } label: {
                Label(searchButtonTitle, systemImage: "magnifyingglass")
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.primary)
            .disabled(viewModel.isLoading || (viewModel.searchMode == .city && viewModel.cities.isEmpty))
        }
        .padding(14)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(Color.primary.opacity(0.06))
        }
    }

    private var districtPickerLabel: String {
        if viewModel.isLoadingDirectory, viewModel.districts.isEmpty {
            return "Yükleniyor…"
        }
        if viewModel.selectedDistrict.isEmpty {
            return "Tüm ilçeler"
        }
        return viewModel.selectedDistrict
    }

    private var searchSummaryText: String {
        switch viewModel.searchMode {
        case .nearby:
            "Konumuma göre"
        case .city:
            viewModel.selectedDistrict.isEmpty ? viewModel.selectedCity : "\(viewModel.selectedCity) / \(viewModel.selectedDistrict)"
        }
    }

    private var searchButtonTitle: String {
        switch viewModel.searchMode {
        case .nearby:
            "Yakındaki Eczaneleri Ara"
        case .city:
            "Eczane Ara"
        }
    }

    private func configureLocationMonitoring() {
        let enabled = viewModel.searchMode == .nearby
        if enabled {
            locationManager.onLocationUpdate = { location in
                Task { @MainActor in
                    viewModel.handleSignificantLocationChange(location, locationManager: locationManager)
                }
            }
        } else {
            locationManager.onLocationUpdate = nil
        }
        locationManager.setContinuousMonitoringEnabled(enabled)
    }

    private func performSearch(forceRefresh: Bool = false, isPullToRefresh: Bool = false) async {
        let didFindResults = await viewModel.search(
            locationManager: locationManager,
            forceRefresh: forceRefresh,
            isPullToRefresh: isPullToRefresh
        )
        if didFindResults, AppConfig.adsEnabled {
            interstitialAdManager.recordSuccessfulSearch()
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: {
            let model = HomeViewModel()
            model.usePreviewData()
            return model
        }())
    }
    .environmentObject(LocationManager())
    .environmentObject(InterstitialAdManager())
}
