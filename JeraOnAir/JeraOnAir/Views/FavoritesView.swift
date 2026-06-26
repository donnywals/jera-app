import SwiftUI

struct FavoritesView: View {
    @ObservedObject var store: TimetableStore
    @ObservedObject var favorites: FavoritesStore

    private var items: [FavoritePerformance] {
        store.favoritePerformances(using: favorites)
    }

    var body: some View {
        Group {
            if let error = store.loadError {
                ContentUnavailableView(
                    "Could not load timetable",
                    systemImage: "exclamationmark.triangle",
                    description: Text(error)
                )
            } else if items.isEmpty {
                ContentUnavailableView(
                    "No favorites yet",
                    systemImage: "star",
                    description: Text("Tap the star on any band in the timetable to save it here.")
                )
            } else {
                List {
                    ForEach(items) { item in
                        PerformanceListRow(
                            bandName: item.performance.name,
                            time: item.performance.time,
                            stageName: "\(item.festivalDay.rawValue) · \(item.stageName)"
                        ) {
                            FavoriteButton(
                                favorites: favorites,
                                day: item.festivalDay,
                                bandId: item.performance.bandId
                            )
                        }
                        .listRowBackground(JeraTheme.bodyColor2)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(JeraTheme.bodyColor1)
        .navigationTitle("Favorites")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(JeraTheme.bodyColor1, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
