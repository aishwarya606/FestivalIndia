import SwiftUI

struct HomeView<P: HomePresenting & ObservableObject>: View {
    @ObservedObject var presenter: P

    let makeDetailView: (UUID) -> AnyView
    let makeSettingsView: () -> AnyView

    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if let next = presenter.viewState.nextFestival {
                        NextFestivalBanner(model: next) {
                            navigateTo(festivalID: next.festivalID)
                        }
                    }
                    regionPicker
                    festivalList
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Indian Festivals 🇮🇳")
            .searchable(text: searchBinding, prompt: "Search festivals…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: presenter.viewState.notificationsEnabled ? "bell.fill" : "bell")
                            .foregroundStyle(presenter.viewState.notificationsEnabled ? .orange : .primary)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                makeSettingsView()
            }
            .onAppear { presenter.onAppear() }
        }
    }

    // MARK: - Region picker

    private var regionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(presenter.viewState.regionTabs) { tab in
                    RegionChipView(
                        item: tab,
                        isSelected: presenter.viewState.selectedRegion == tab.region
                    ) {
                        presenter.selectRegion(tab.region)
                    }
                }
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Festival list

    private var festivalList: some View {
        LazyVStack(spacing: 12) {
            if presenter.viewState.festivals.isEmpty {
                EmptyStateView(
                    systemImage: "magnifyingglass",
                    title: "No festivals found",
                    subtitle: "Try a different search term or region."
                )
            } else {
                ForEach(presenter.viewState.festivals) { model in
                    NavigationLink(destination: makeDetailView(model.id)) {
                        FestivalCardView(model: model)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Helpers

    private var searchBinding: Binding<String> {
        Binding(
            get: { presenter.viewState.searchText },
            set: { presenter.updateSearch($0) }
        )
    }

    private func navigateTo(festivalID: UUID) -> some View {
        makeDetailView(festivalID)
    }
}
