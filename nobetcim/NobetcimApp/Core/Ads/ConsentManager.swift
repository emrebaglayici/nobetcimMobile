import Foundation
import UIKit

#if canImport(UserMessagingPlatform)
import UserMessagingPlatform
#endif

@MainActor
final class ConsentManager {
    static let shared = ConsentManager()
    private var hasStarted = false

    private init() {}

    func prepareConsentFlow() {
        Task {
            await requestConsentIfNeeded()
        }
    }

    func requestConsentIfNeeded() async {
        guard !hasStarted else { return }
        hasStarted = true

        #if canImport(UserMessagingPlatform)
        await requestUMPConsent()
        #endif
    }

    #if canImport(UserMessagingPlatform)
    private func requestUMPConsent() async {
        let parameters = RequestParameters()
        let consentInfo = ConsentInformation.shared

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            consentInfo.requestConsentInfoUpdate(with: parameters) { error in
                if let error {
                    #if DEBUG
                    print("UMP consent info update failed:", error.localizedDescription)
                    #endif
                    continuation.resume()
                    return
                }

                guard consentInfo.formStatus == .available else {
                    continuation.resume()
                    return
                }

                guard let presenter = Self.topViewController() else {
                    continuation.resume()
                    return
                }

                ConsentForm.loadAndPresentIfRequired(from: presenter) { _ in
                    continuation.resume()
                }
            }
        }
    }
    #endif

    private static func topViewController() -> UIViewController? {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController else {
            return nil
        }
        return topPresenter(from: root)
    }

    private static func topPresenter(from controller: UIViewController) -> UIViewController {
        if let presented = controller.presentedViewController {
            return topPresenter(from: presented)
        }
        if let navigation = controller as? UINavigationController, let visible = navigation.visibleViewController {
            return topPresenter(from: visible)
        }
        if let tab = controller as? UITabBarController, let selected = tab.selectedViewController {
            return topPresenter(from: selected)
        }
        return controller
    }
}
