import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var interstitialAdManager: InterstitialAdManager
    @Environment(\.scenePhase) private var scenePhase
    @State private var isSearchOptionsExpanded = false

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
        .navigationTitle("Nöbetçim")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            interstitialAdManager.load()
            configureLocationMonitoring()
            Task {
                await viewModel.loadDirectory()
            }
            if !viewModel.hasSearched && viewModel.searchMode == .nearby {
                await performSearch()
            }
        }
        .onChange(of: viewModel.searchMode) {
            configureLocationMonitoring()
            guard viewModel.searchMode == .city else { return }
            Task {
                await viewModel.loadDirectory()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else {
                locationManager.setContinuousMonitoringEnabled(false)
                return
            }
            configureLocationMonitoring()
            interstitialAdManager.recordAppBecameActive()
            Task {
                await viewModel.refreshNearbyForWidgetIfNeeded(locationManager: locationManager)
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
                            pickerRow(title: "İl") {
                                Picker("İl", selection: $viewModel.selectedCity) {
                                    if viewModel.cities.isEmpty {
                                        Text("İller yükleniyor").tag(viewModel.selectedCity)
                                    } else {
                                        ForEach(viewModel.cities, id: \.self) { city in
                                            Text(city).tag(city)
                                        }
                                    }
                                }
                            }

                            pickerRow(title: "İlçe") {
                                Picker("İlçe", selection: $viewModel.selectedDistrict) {
                                    Text("Tüm ilçeler").tag("")
                                    if viewModel.isLoadingDirectory {
                                        Text("İlçeler yükleniyor").tag("")
                                    } else {
                                        ForEach(viewModel.districts, id: \.self) { district in
                                            Text(district).tag(district)
                                        }
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.selectedCity) {
                            viewModel.updateDistrictForSelectedCity()
                            Task {
                                await viewModel.loadDistrictsForSelectedCity()
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

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            content()
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(AppTheme.primary)
        }
        .padding(.horizontal, 12)
        .frame(height: 42)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10))
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
        if didFindResults {
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
