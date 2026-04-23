import XCTest
@testable import FestivalsIndia

@MainActor
final class HomePresenterTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(
        festivals: [Festival] = MockFestivals.samples,
        notificationGranted: Bool = true
    ) -> (HomePresenter, MockFestivalRepository, MockNotificationService) {
        let repo = MockFestivalRepository(festivals: festivals)
        let notif = MockNotificationService()
        notif.shouldGrantPermission = notificationGranted
        let presenter = HomePresenter(
            repository: repo,
            notificationService: notif,
            yearRange: 2026...2026
        )
        return (presenter, repo, notif)
    }

    // MARK: - onAppear

    func test_onAppear_populatesRegionTabs() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        XCTAssertEqual(sut.viewState.regionTabs.count, Region.allCases.count)
    }

    func test_onAppear_showsAllFestivals_whenRegionIsAll() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        XCTAssertEqual(sut.viewState.festivals.count, MockFestivals.samples.count)
    }

    func test_onAppear_reflectsNotificationStatus_whenAuthorized() {
        let (sut, _, notif) = makeSUT()
        notif.authorizationStatus = .authorized
        sut.onAppear()
        XCTAssertTrue(sut.viewState.notificationsEnabled)
    }

    func test_onAppear_reflectsNotificationStatus_whenDenied() {
        let (sut, _, notif) = makeSUT()
        notif.authorizationStatus = .denied
        sut.onAppear()
        XCTAssertFalse(sut.viewState.notificationsEnabled)
    }

    // MARK: - Region filtering

    func test_selectRegion_filtersToNorthFestivals() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.selectRegion(.north)

        let northOnly = sut.viewState.festivals.allSatisfy { $0.regionLabel == Region.north.rawValue }
        XCTAssertTrue(northOnly, "Expected only North India festivals after selecting .north")
    }

    func test_selectRegion_filtersToSouthFestivals() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.selectRegion(.south)

        XCTAssertEqual(sut.viewState.festivals.count, 1)
        XCTAssertEqual(sut.viewState.festivals.first?.name, "Pongal")
    }

    func test_selectRegion_all_showsAllFestivals() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.selectRegion(.south)
        sut.selectRegion(.all)

        XCTAssertEqual(sut.viewState.festivals.count, MockFestivals.samples.count)
    }

    func test_selectRegion_returnsEmpty_whenNoFestivalsInRegion() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.selectRegion(.east)   // no east festivals in mock samples

        XCTAssertTrue(sut.viewState.festivals.isEmpty)
    }

    // MARK: - Search

    func test_updateSearch_filtersByName() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.updateSearch("Diwali")

        XCTAssertEqual(sut.viewState.festivals.count, 1)
        XCTAssertEqual(sut.viewState.festivals.first?.name, "Diwali")
    }

    func test_updateSearch_filtersByTagline() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.updateSearch("harvest")   // matches Pongal tagline AND Lohri tagline

        XCTAssertTrue(sut.viewState.festivals.count >= 1)
        XCTAssertTrue(sut.viewState.festivals.allSatisfy {
            $0.name == "Pongal" || $0.name == "Lohri"
        })
    }

    func test_updateSearch_isCaseInsensitive() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.updateSearch("dIwAlI")

        XCTAssertEqual(sut.viewState.festivals.first?.name, "Diwali")
    }

    func test_updateSearch_emptyQuery_returnsAll() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.updateSearch("Diwali")
        sut.updateSearch("")

        XCTAssertEqual(sut.viewState.festivals.count, MockFestivals.samples.count)
    }

    func test_updateSearch_noMatch_returnsEmpty() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.updateSearch("xyznosuchfestival")

        XCTAssertTrue(sut.viewState.festivals.isEmpty)
    }

    // MARK: - Search + Region combined

    func test_search_withinSelectedRegion_respectsRegionFilter() {
        let (sut, _, _) = makeSUT()
        sut.onAppear()
        sut.selectRegion(.north)
        sut.updateSearch("Diwali")   // Diwali is panIndia, not north

        // Diwali should not appear because region filter is North
        XCTAssertTrue(sut.viewState.festivals.isEmpty)
    }

    // MARK: - Display model correctness

    func test_festivalRowDisplayModel_hasCorrectName() {
        let (sut, _, _) = makeSUT(festivals: [MockFestivals.pongal])
        sut.onAppear()

        XCTAssertEqual(sut.viewState.festivals.first?.name, "Pongal")
    }

    func test_festivalRowDisplayModel_hasCorrectRegionLabel() {
        let (sut, _, _) = makeSUT(festivals: [MockFestivals.pongal])
        sut.onAppear()

        XCTAssertEqual(sut.viewState.festivals.first?.regionLabel, Region.south.rawValue)
    }

    // MARK: - Notifications

    func test_enableNotifications_schedulesRemindersWhenGranted() async {
        let (sut, _, notif) = makeSUT(notificationGranted: true)
        await sut.enableNotifications()

        XCTAssertEqual(notif.scheduleRemindersCallCount, 1)
        XCTAssertTrue(sut.viewState.notificationsEnabled)
    }

    func test_enableNotifications_doesNotScheduleWhenDenied() async {
        let (sut, _, notif) = makeSUT(notificationGranted: false)
        await sut.enableNotifications()

        XCTAssertEqual(notif.scheduleRemindersCallCount, 0)
        XCTAssertFalse(sut.viewState.notificationsEnabled)
    }

    func test_disableNotifications_cancelsAndUpdatesState() async {
        let (sut, _, notif) = makeSUT()
        sut.onAppear()
        await sut.disableNotifications()

        XCTAssertEqual(notif.cancelAllRemindersCallCount, 1)
        XCTAssertFalse(sut.viewState.notificationsEnabled)
    }
}
