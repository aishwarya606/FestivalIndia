import SwiftUI

@main
struct FestivalIndiaApp: App {

    private let container = DependencyContainer()
    @StateObject private var homePresenter: HomePresenter

    init() {
        let container = DependencyContainer()
        _homePresenter = StateObject(wrappedValue: container.makeHomePresenter())
    }

    var body: some Scene {
        WindowGroup {
            HomeView(
                presenter: homePresenter,
                makeDetailView: { festivalID in
                    container.makeDetailView(for: festivalID)
                },
                makeSettingsView: {
                    container.makeSettingsView()
                }
            )
        }
    }
}
