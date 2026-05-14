import SwiftUI

@main
struct NobetcimApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var interstitialAdManager = InterstitialAdManager()

    init() {
        AdMobManager.shared.configure()
        ConsentManager.shared.prepareConsentFlow()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(locationManager)
                .environmentObject(interstitialAdManager)
                .tint(AppTheme.primary)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var interstitialAdManager: InterstitialAdManager

    @StateObject private var pharmacyViewModel = PharmacyViewModel()
    @State private var selectedTab: AppTab = .pharmacies

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(viewModel: pharmacyViewModel)
            }
            .tabItem {
                Label("Eczaneler", systemImage: "cross.case.fill")
            }
            .tag(AppTab.pharmacies)

            NavigationStack {
                if selectedTab == .map {
                    PharmacyMapView(pharmacies: pharmacyViewModel.pharmacies)
                } else {
                    ProgressView()
                        .navigationTitle("Harita")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .tabItem {
                Label("Harita", systemImage: "map.fill")
            }
            .tag(AppTab.map)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Daha Fazla", systemImage: "ellipsis.circle.fill")
            }
            .tag(AppTab.more)
        }
    }
}

private enum AppTab: Hashable {
    case pharmacies
    case map
    case more
}
