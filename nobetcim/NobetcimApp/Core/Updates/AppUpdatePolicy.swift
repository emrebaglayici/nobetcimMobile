import Foundation

struct AppUpdatePolicy: Decodable {
    let minimumVersion: String
    let minimumBuild: Int?
    let message: String?
    let appStoreURL: String?

    static let fallbackAppStoreURL = "https://apps.apple.com/tr/app/id6771044026"

    var resolvedMessage: String {
        message ?? "Devam etmek için lütfen uygulamayı App Store'dan güncelleyin."
    }

    var resolvedAppStoreURL: URL {
        URL(string: appStoreURL ?? Self.fallbackAppStoreURL)
            ?? URL(string: Self.fallbackAppStoreURL)!
    }
}
