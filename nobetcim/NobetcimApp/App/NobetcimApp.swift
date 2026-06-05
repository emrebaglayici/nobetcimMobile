import SwiftUI

@main
struct NobetcimApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var interstitialAdManager = InterstitialAdManager()
    @StateObject private var widgetLocationCoordinator = WidgetLocationCoordinator()

    init() {
        if AppConfig.adsEnabled {
            AdMobManager.shared.configure()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(locationManager)
                .environmentObject(interstitialAdManager)
                .environmentObject(widgetLocationCoordinator)
                .tint(AppTheme.primary)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var locationManager: LocationManager
    @EnvironmentObject private var interstitialAdManager: InterstitialAdManager
    @EnvironmentObject private var widgetLocationCoordinator: WidgetLocationCoordinator
    @Environment(\.scenePhase) private var scenePhase

    @StateObject private var pharmacyViewModel = PharmacyViewModel()
    @State private var selectedTab: AppTab = .pharmacies
    @State private var forceUpdateRequired = false
    @State private var forceUpdateMessage = ""
    @State private var forceUpdateURL = URL(string: AppUpdatePolicy.fallbackAppStoreURL)!

    var body: some View {
        Group {
            if forceUpdateRequired {
                ForceUpdateView(message: forceUpdateMessage, appStoreURL: forceUpdateURL)
            } else {
                mainTabs
            }
        }
        .task {
            widgetLocationCoordinator.attach(to: locationManager)
            await checkForRequiredUpdate()
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            widgetLocationCoordinator.refreshMonitoring()
        }
        .onChange(of: scenePhase) { _, newPhase in
            AppSessionClock.shared.scenePhaseChanged(newPhase)
            if newPhase == .active {
                widgetLocationCoordinator.refreshMonitoring()
                Task {
                    await checkForRequiredUpdate()
                    await widgetLocationCoordinator.syncNow()
                }
            }
        }
    }

    private var mainTabs: some View {
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
        .task {
            if AppConfig.adsEnabled {
                await ConsentManager.shared.requestConsentIfNeeded()
            }
        }
        .onChange(of: selectedTab) { _, _ in
            if AppConfig.adsEnabled {
                interstitialAdManager.recordTabChange()
            }
        }
    }

    @MainActor
    private func checkForRequiredUpdate() async {
        do {
            let policy = try await AppUpdateService.shared.fetchPolicy()
            guard AppUpdateService.shared.requiresForceUpdate(policy: policy) else { return }
            forceUpdateMessage = policy.resolvedMessage
            forceUpdateURL = policy.resolvedAppStoreURL
            forceUpdateRequired = true
        } catch {
            // Ağ hatasında uygulamayı kilitleme; bir sonraki açılışta tekrar dene.
        }
    }
}

enum AppTab: Hashable {
    case pharmacies
    case map
    case more
}
