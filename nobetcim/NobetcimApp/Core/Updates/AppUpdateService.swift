import Foundation

@MainActor
final class AppUpdateService {
    static let shared = AppUpdateService()

    private let policyURL: URL
    private let session: URLSession

    init(
        policyURL: URL = AppConfig.minimumVersionPolicyURL,
        session: URLSession = .shared
    ) {
        self.policyURL = policyURL
        self.session = session
    }

    func fetchPolicy() async throws -> AppUpdatePolicy {
        var request = URLRequest(url: policyURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 12

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(AppUpdatePolicy.self, from: data)
    }

    func requiresForceUpdate(policy: AppUpdatePolicy) -> Bool {
        let currentVersion = AppConfig.marketingVersion
        let currentBuild = AppConfig.buildNumber

        if AppVersionComparator.isVersion(currentVersion, olderThan: policy.minimumVersion) {
            return true
        }

        if AppVersionComparator.compare(currentVersion, policy.minimumVersion) == .orderedSame,
           let minimumBuild = policy.minimumBuild,
           currentBuild < minimumBuild {
            return true
        }

        return false
    }
}
