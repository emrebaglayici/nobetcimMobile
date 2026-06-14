import XCTest
@testable import nobetcim

final class NearbyRefreshPolicyTests: XCTestCase {
    override func setUp() {
        super.setUp()
        NearbyRefreshPolicy.resetForTesting()
    }

    func testNetworkRequiredWhenCacheMissing() {
        XCTAssertTrue(
            NearbyRefreshPolicy.shouldPerformNetworkFetch(forceRefresh: false, hasTodayCache: false)
        )
    }

    func testCachedDataSkipsNetworkWithoutForceRefresh() {
        XCTAssertFalse(
            NearbyRefreshPolicy.shouldPerformNetworkFetch(forceRefresh: false, hasTodayCache: true)
        )
    }

    func testForceRefreshUsesNetworkWhenNoPriorFetchRecorded() {
        XCTAssertTrue(
            NearbyRefreshPolicy.shouldPerformNetworkFetch(forceRefresh: true, hasTodayCache: true)
        )
    }

    func testForceRefreshThrottledWithinFiveMinutes() {
        NearbyRefreshPolicy.recordNetworkFetch()
        XCTAssertFalse(
            NearbyRefreshPolicy.shouldPerformNetworkFetch(forceRefresh: true, hasTodayCache: true)
        )
    }

    func testIgnoreThrottleBypassesCooldown() {
        NearbyRefreshPolicy.recordNetworkFetch()
        XCTAssertTrue(
            NearbyRefreshPolicy.shouldPerformNetworkFetch(
                forceRefresh: true,
                hasTodayCache: true,
                ignoreThrottle: true
            )
        )
    }
}
