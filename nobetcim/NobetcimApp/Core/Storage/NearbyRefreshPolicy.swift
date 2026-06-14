import Foundation

/// Yakın eczane API çağrılarını sınırlar; günlük önbellek varken gereksiz ağ isteğini engeller.
enum NearbyRefreshPolicy {
    /// Aynı gün içinde tekrar ağ isteği için minimum süre.
    static let minNetworkInterval: TimeInterval = 5 * 60

    private static var lastNetworkFetchAt: Date?

    static func shouldPerformNetworkFetch(forceRefresh: Bool, hasTodayCache: Bool, ignoreThrottle: Bool = false) -> Bool {
        if ignoreThrottle { return true }
        if !hasTodayCache { return true }
        if !forceRefresh { return false }

        guard let lastNetworkFetchAt else { return true }
        return Date().timeIntervalSince(lastNetworkFetchAt) >= minNetworkInterval
    }

    static func recordNetworkFetch() {
        lastNetworkFetchAt = Date()
    }

    #if DEBUG
    static func resetForTesting() {
        lastNetworkFetchAt = nil
    }
    #endif
}
