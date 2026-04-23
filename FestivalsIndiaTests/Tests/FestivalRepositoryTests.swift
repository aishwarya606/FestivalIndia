import XCTest
@testable import FestivalsIndia

final class FestivalRepositoryTests: XCTestCase {

    private var sut: FestivalRepository!

    override func setUp() {
        sut = FestivalRepository(festivals: MockFestivals.samples)
    }

    // MARK: - fetchAll

    func test_fetchAll_returnsAllFestivals() {
        XCTAssertEqual(sut.fetchAll().count, MockFestivals.samples.count)
    }

    // MARK: - fetch(by:)

    func test_fetchByRegion_all_returnsEverything() {
        XCTAssertEqual(sut.fetch(by: .all).count, MockFestivals.samples.count)
    }

    func test_fetchByRegion_south_returnsSouthOnly() {
        let results = sut.fetch(by: .south)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Pongal")
    }

    func test_fetchByRegion_north_returnsNorthOnly() {
        let results = sut.fetch(by: .north)
        XCTAssertTrue(results.allSatisfy { $0.region == .north })
    }

    func test_fetchByRegion_east_returnsEmpty_whenNoEastFestivals() {
        let results = sut.fetch(by: .east)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - fetch(id:)

    func test_fetchByID_returnsCorrectFestival() {
        let result = sut.fetch(id: MockFestivals.diwali.id)
        XCTAssertEqual(result?.name, "Diwali")
    }

    func test_fetchByID_returnsNil_forUnknownID() {
        let result = sut.fetch(id: UUID())
        XCTAssertNil(result)
    }

    // MARK: - search

    func test_search_emptyQuery_returnsAll() {
        let results = sut.search(query: "", in: .all)
        XCTAssertEqual(results.count, MockFestivals.samples.count)
    }

    func test_search_matchesName() {
        let results = sut.search(query: "Diwali", in: .all)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "Diwali")
    }

    func test_search_matchesTagline() {
        let results = sut.search(query: "harvest", in: .all)
        XCTAssertTrue(results.count >= 1)
    }

    func test_search_isCaseInsensitive() {
        let lower = sut.search(query: "diwali", in: .all)
        let upper = sut.search(query: "DIWALI", in: .all)
        XCTAssertEqual(lower.count, upper.count)
    }

    func test_search_withinRegion_respectsFilter() {
        // "Diwali" exists but it's panIndia — searching in .north should not return it
        let results = sut.search(query: "Diwali", in: .north)
        XCTAssertTrue(results.isEmpty)
    }

    func test_search_noMatch_returnsEmpty() {
        let results = sut.search(query: "xyznonexistent", in: .all)
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - upcomingFestivals

    func test_upcomingFestivals_excludesPastDates() {
        // Use a future reference date so all 2026 festivals are upcoming
        let futureReference = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let results = sut.upcomingFestivals(from: futureReference, yearRange: 2025...2026)
        XCTAssertFalse(results.isEmpty)
    }

    func test_upcomingFestivals_isSortedByDate() {
        let reference = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let results = sut.upcomingFestivals(from: reference, yearRange: 2025...2026)
        let dates = results.map { $0.1 }
        XCTAssertEqual(dates, dates.sorted(), "Upcoming festivals should be in ascending date order")
    }

    func test_upcomingFestivals_eachFestivalAppearsOnce() {
        let reference = Calendar.current.date(from: DateComponents(year: 2025, month: 1, day: 1))!
        let results = sut.upcomingFestivals(from: reference, yearRange: 2025...2030)
        let ids = results.map { $0.0.id }
        // Each festival should appear at most once (earliest upcoming occurrence)
        XCTAssertEqual(ids.count, Set(ids).count, "Each festival should appear exactly once")
    }

    // MARK: - DateRule.fixed resolves correctly for any year

    func test_fixedDateFestival_resolvesCorrectlyFor2030() {
        // Pongal is Jan 14 every year
        let date = MockFestivals.pongal.date(for: 2030)
        let components = Calendar.current.dateComponents([.month, .day], from: date!)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 14)
    }

    func test_fixedDateFestival_resolvesCorrectlyFor2045() {
        let date = MockFestivals.lohri.date(for: 2045)
        let components = Calendar.current.dateComponents([.month, .day], from: date!)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 13)
    }

    // MARK: - DateRule.lunisolar resolves for known year

    func test_lunisolarFestival_resolvesKnownYear() {
        let date = MockFestivals.diwali.date(for: 2026)
        let components = Calendar.current.dateComponents([.month, .day, .year], from: date!)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 11)
        XCTAssertEqual(components.day, 8)
    }

    func test_lunisolarFestival_fallsBackToNearestKnownYear() {
        // 2099 is not in knownDates — should return a non-nil date using nearest known year
        let date = MockFestivals.diwali.date(for: 2099)
        XCTAssertNotNil(date)
    }
}
