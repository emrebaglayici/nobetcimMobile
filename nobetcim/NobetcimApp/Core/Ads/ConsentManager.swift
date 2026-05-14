import Foundation

final class ConsentManager {
    static let shared = ConsentManager()
    private init() {}

    func prepareConsentFlow() {
        // TODO: Integrate UMP consent request before production release.
        // Keep emergency actions available even if consent loading fails.
    }
}
