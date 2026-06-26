import Foundation

struct FavoritePerformance: Identifiable, Hashable {
    let festivalDay: FestivalDay
    let stageName: String
    let performance: Performance

    var id: String {
        FavoritePerformanceKey(festivalDay: festivalDay, bandId: performance.bandId).storageValue
    }

    func startDate(in timetable: DayTimetable) -> Date {
        performance.startDate(in: timetable)
    }
}

extension TimetableStore {
    func favoritePerformances(using favorites: FavoritesStore) -> [FavoritePerformance] {
        favorites.favorites.compactMap { key in
            guard let timetable = timetable(for: key.festivalDay),
                  let match = timetable.stages.compactMap({ stage -> FavoritePerformance? in
                      guard let performance = stage.performances.first(where: { $0.bandId == key.bandId }) else {
                          return nil
                      }
                      return FavoritePerformance(
                          festivalDay: key.festivalDay,
                          stageName: stage.name,
                          performance: performance
                      )
                  }).first else {
                return nil
            }
            return match
        }
        .sorted { lhs, rhs in
            let dayOrder = FestivalDay.allCases
            if lhs.festivalDay != rhs.festivalDay {
                let leftIndex = dayOrder.firstIndex(of: lhs.festivalDay) ?? 0
                let rightIndex = dayOrder.firstIndex(of: rhs.festivalDay) ?? 0
                return leftIndex < rightIndex
            }

            guard let leftTimetable = timetable(for: lhs.festivalDay),
                  let rightTimetable = timetable(for: rhs.festivalDay) else {
                return lhs.performance.name < rhs.performance.name
            }

            return lhs.startDate(in: leftTimetable) < rhs.startDate(in: rightTimetable)
        }
    }
}
