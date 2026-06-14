import CoreLocation
import XCTest
@testable import nobetcim

@MainActor
final class NearbySearchBehaviorTests: XCTestCase {
    private let istanbulLocation = CLLocation(latitude: 41.0082, longitude: 28.9784)

    private var repository: MockPharmacyRepository!
    private var locationManager: LocationManager!
    private var viewModel: PharmacyViewModel!

    private let samplePharmacies: [Pharmacy] = [
        Pharmacy(
            id: "p1",
            name: "Test Eczanesi",
            city: "İstanbul",
            district: "Kadıköy",
            address: "Test Cad.",
            phone: nil,
            latitude: 41.01,
            longitude: 28.98,
            distanceKm: 1.2,
            date: nil,
            source: nil
        )
    ]

    override func setUp() {
        super.setUp()
        NearbyRefreshPolicy.resetForTesting()
        repository = MockPharmacyRepository()
        locationManager = LocationManager()
        locationManager.setTestLocation(istanbulLocation)
        viewModel = PharmacyViewModel(repository: repository)
        viewModel.searchMode = .nearby
    }

    func testPullToRefreshDoesNotForceNetwork() async {
        repository.nearbyResults = samplePharmacies
        viewModel.pharmacies = samplePharmacies
        viewModel.hasSearched = true

        let success = await viewModel.search(
            locationManager: locationManager,
            isPullToRefresh: true
        )

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.pharmacies.count, 1)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(repository.nearbyCalls.count, 1)
        XCTAssertEqual(repository.nearbyCalls[0].forceRefresh, false)
        XCTAssertEqual(repository.nearbyCalls[0].ignoreThrottle, false)
    }

    func testPullToRefreshKeepsPreviousResultsWhenRepositoryReturnsEmpty() async {
        viewModel.pharmacies = samplePharmacies
        viewModel.hasSearched = true
        repository.nearbyResults = []

        let success = await viewModel.search(
            locationManager: locationManager,
            isPullToRefresh: true
        )

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.pharmacies, samplePharmacies)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPullToRefreshKeepsPreviousResultsWhenRepositoryThrows() async {
        viewModel.pharmacies = samplePharmacies
        viewModel.hasSearched = true
        repository.nearbyError = URLError(.notConnectedToInternet)

        let success = await viewModel.search(
            locationManager: locationManager,
            isPullToRefresh: true
        )

        XCTAssertTrue(success)
        XCTAssertEqual(viewModel.pharmacies, samplePharmacies)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPullToRefreshDoesNotShowLoadingOverlayWhenResultsExist() async {
        viewModel.pharmacies = samplePharmacies
        viewModel.hasSearched = true
        repository.nearbyResults = samplePharmacies

        _ = await viewModel.search(
            locationManager: locationManager,
            isPullToRefresh: true
        )

        XCTAssertFalse(viewModel.isLoading)
    }

    func testRetryForcesNetworkAndIgnoresThrottle() async {
        NearbyRefreshPolicy.recordNetworkFetch()
        repository.nearbyResults = samplePharmacies

        _ = await viewModel.search(
            locationManager: locationManager,
            forceRefresh: true,
            ignoreNetworkThrottle: true
        )

        XCTAssertEqual(repository.nearbyCalls.count, 1)
        XCTAssertEqual(repository.nearbyCalls[0].forceRefresh, true)
        XCTAssertEqual(repository.nearbyCalls[0].ignoreThrottle, true)
    }

    func testInitialNearbySearchUsesNetworkWhenCacheUnavailable() async {
        repository.nearbyResults = samplePharmacies

        _ = await viewModel.search(locationManager: locationManager)

        XCTAssertEqual(repository.nearbyCalls.count, 1)
        XCTAssertEqual(repository.nearbyCalls[0].forceRefresh, false)
    }
}
