import XCTest
@testable import FestivalsIndia

@MainActor
final class FestivalDetailPresenterTests: XCTestCase {

    // MARK: - Helpers

    private func makeSUT(festival: Festival = MockFestivals.pongal) -> (FestivalDetailPresenter, MockFestivalRepository) {
        let repo = MockFestivalRepository(festivals: [festival])
        let presenter = FestivalDetailPresenter(festivalID: festival.id, repository: repo)
        return (presenter, repo)
    }

    // MARK: - Loading state

    func test_initialState_isLoading() {
        let (sut, _) = makeSUT()
        XCTAssertTrue(sut.viewState.isLoading)
        XCTAssertNil(sut.viewState.content)
    }

    func test_onAppear_setsLoadingFalse() {
        let (sut, _) = makeSUT()
        sut.onAppear()
        XCTAssertFalse(sut.viewState.isLoading)
    }

    // MARK: - Content mapping

    func test_onAppear_mapsNameCorrectly() {
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertEqual(sut.viewState.content?.name, "Pongal")
    }

    func test_onAppear_mapsEmojiCorrectly() {
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertEqual(sut.viewState.content?.emoji, "🌾")
    }

    func test_onAppear_mapsRegionLabelCorrectly() {
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertEqual(sut.viewState.content?.regionLabel, Region.south.rawValue)
    }

    func test_onAppear_mapsImportanceCorrectly() {
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertEqual(sut.viewState.content?.importance, "Pongal importance text.")
    }

    func test_onAppear_mapsRitualsCorrectly() {
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertEqual(sut.viewState.content?.rituals, ["Cook pongal", "Shout Pongalo Pongal"])
    }

    func test_onAppear_mapsFunFactsCorrectly() {
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertEqual(sut.viewState.content?.funFacts, ["2000 years old"])
    }

    // MARK: - Unknown festival ID

    func test_onAppear_withUnknownID_contentRemainsNil() {
        let repo = MockFestivalRepository(festivals: [MockFestivals.pongal])
        let unknownID = UUID()
        let sut = FestivalDetailPresenter(festivalID: unknownID, repository: repo)
        sut.onAppear()
        XCTAssertNil(sut.viewState.content)
    }

    // MARK: - Fixed-date festival countdown

    func test_fixedDateFestival_producesNonNilDateText() {
        // Pongal is Jan 14 every year — always has a future date
        let (sut, _) = makeSUT(festival: MockFestivals.pongal)
        sut.onAppear()
        XCTAssertFalse(sut.viewState.content?.dateText.isEmpty ?? true)
    }
}
