import XCTest
@testable import nobetcim

final class AppVersionComparatorTests: XCTestCase {
    func testOlderVersionDetection() {
        XCTAssertTrue(AppVersionComparator.isVersion("1.1.4", olderThan: "1.1.5"))
        XCTAssertFalse(AppVersionComparator.isVersion("1.1.5", olderThan: "1.1.5"))
        XCTAssertFalse(AppVersionComparator.isVersion("1.1.6", olderThan: "1.1.5"))
    }
}
