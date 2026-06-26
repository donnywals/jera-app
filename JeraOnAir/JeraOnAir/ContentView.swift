import SwiftUI

struct ContentView: View {
    @StateObject private var store = TimetableStore()
    @StateObject private var favorites = FavoritesStore()
    @State private var selectedDay = FestivalDay.currentFestivalDay
    @State private var scrollTrigger = UUID()
    @State private var displayMode: TimetableDisplayMode = .grid
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            NavigationStack {
                timetableTab
            }
            .tabItem {
                Label("Timetable", systemImage: "calendar")
            }

            NavigationStack {
                FavoritesView(store: store, favorites: favorites)
            }
            .tabItem {
                Label("Favorites", systemImage: "star.fill")
            }
        }
        .tint(JeraTheme.accentGold)
        .onAppear(perform: focusCurrentDay)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                focusCurrentDay()
            }
        }
    }

    private var timetableTab: some View {
        VStack(spacing: 0) {
            dayTabBar

            if let error = store.loadError {
                Spacer()
                ContentUnavailableView(
                    "Could not load timetable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
                Spacer()
            } else if let timetable = store.timetable(for: selectedDay) {
                TimetableDayContainerView(
                    timetable: timetable,
                    selectedDay: selectedDay,
                    isCurrentFestivalDay: selectedDay == FestivalDay.currentFestivalDay,
                    scrollTrigger: scrollTrigger,
                    favorites: favorites,
                    displayMode: $displayMode
                )
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .background(JeraTheme.bodyColor1.ignoresSafeArea())
        .navigationTitle("Timetable")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(JeraTheme.bodyColor1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var dayTabBar: some View {
        HStack(spacing: 8) {
            ForEach(FestivalDay.allCases) { day in
                Button {
                    selectedDay = day
                } label: {
                    Text(day.rawValue)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selectedDay == day ? JeraTheme.accentGold : JeraTheme.bodyColor2)
                        .foregroundStyle(selectedDay == day ? JeraTheme.bodyColor1 : JeraTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(JeraTheme.bodyColor1)
    }

    private func focusCurrentDay() {
        selectedDay = FestivalDay.currentFestivalDay
        scrollTrigger = UUID()
    }
}

#Preview {
    ContentView()
}
