import Foundation

enum AppConfig {
    static let appName = "Nöbetçim"
    static let supportEmail = "destek@nobetcim.info"
    static let appGroupID = "group.talhagergin.nobetcim"

    static var baseURL: URL {
        let value = configValue(for: "NOBETECZA_BASE_URL")
        return URL(string: value?.nilIfPlaceholder ?? "https://api.nobetecza.com")!
    }

    static var apiKey: String {
        let value = configValue(for: "NOBETECZA_API_KEY")
        return value?.nilIfPlaceholder ?? ""
    }

    static var bannerAdUnitID: String {
        let value = configValue(for: "ADMOB_BANNER_ID")
        return value?.nilIfPlaceholder ?? "ca-app-pub-3940256099942544/2435281174"
    }

    static var interstitialAdUnitID: String {
        let value = configValue(for: "ADMOB_INTERSTITIAL_ID")
        return value?.nilIfPlaceholder ?? "ca-app-pub-3940256099942544/4411468910"
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private static func configValue(for key: String) -> String? {
        if let infoValue = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           infoValue.nilIfPlaceholder != nil {
            return infoValue
        }

        guard
            let url = Bundle.main.url(forResource: "NobetcimConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String]
        else {
            return nil
        }
        return plist[key]
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
