import Foundation

enum AppConfig {
    static let appName = "Nöbetçim"
    static let supportEmail = "destek@nobetcim.info"

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
        return URL(string: value ?? "https://api.nobetecza.com")!
    }

    static var apiKey: String {
        resolvedConfigValue(for: "NOBETECZA_API_KEY") ?? ""
    }

    static var bannerAdUnitID: String {
        resolvedConfigValue(for: "ADMOB_BANNER_ID")
            ?? "ca-app-pub-3940256099942544/2435281174"
    }

    static var interstitialAdUnitID: String {
        resolvedConfigValue(for: "ADMOB_INTERSTITIAL_ID")
            ?? "ca-app-pub-3940256099942544/4411468910"
    }

    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
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
