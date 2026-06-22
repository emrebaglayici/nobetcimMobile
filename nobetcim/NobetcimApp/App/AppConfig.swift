import Foundation

enum AppConfig {
    /// Uygulama içi başlık ve App Store adıyla aynı marka adı.
    static let appName = "Nöbetçim Cebinde"
    static let adsEnabled = false
    static let supportEmail = "destek@nobetcim.info"
    static let appStoreURL = "https://apps.apple.com/tr/app/id6771044026"
    static let minimumVersionPolicyURL = URL(string: "https://nobetcim.info/app-version.json")!

    static var marketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    static var buildNumber: Int {
        Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
    }

    static var appVersion: String {
        "\(marketingVersion) (\(buildNumber))"
    }

    static var appGroupID: String {
        if let configured = resolvedConfigValue(for: "APP_GROUP_ID") {
            return configured
        }
        let bundleID = Bundle.main.bundleIdentifier ?? "emrebaglayici.nobetcim"
        let mainID = bundleID.replacingOccurrences(of: ".widget", with: "")
        return "group.\(mainID)"
    }

    static var baseURL: URL {
        let value = resolvedConfigValue(for: "NOBETECZA_BASE_URL")
        return URL(string: value ?? "https://nobetcimbackend.vercel.app/api/v1")!
    }

    static var apiKey: String {
        resolvedConfigValue(for: "NOBETECZA_API_KEY") ?? ""
    }

    static var bannerAdUnitID: String {
        resolvedConfigValue(for: "ADMOB_BANNER_ID")
            ?? "ca-app-pub-8301099664647828/2873724314"
    }

    static var interstitialAdUnitID: String {
        resolvedConfigValue(for: "ADMOB_INTERSTITIAL_ID")
            ?? "ca-app-pub-8301099664647828/6022631831"
    }

    private static func resolvedConfigValue(for key: String) -> String? {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           let cleaned = infoValue.nilIfPlaceholder {
            return cleaned
        }

        guard
            let url = Bundle.main.url(forResource: "NobetcimConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
            let value = plist[key]?.nilIfPlaceholder
        else {
            return nil
        }
        return value
    }
}

private extension String {
    var nilIfPlaceholder: String? {
        if isEmpty || hasPrefix("<") || hasPrefix("$(") {
            return nil
        }
        return self
    }
}
