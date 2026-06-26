import Foundation

struct FavoritePerformanceKey: Hashable, Codable {
    let festivalDay: FestivalDay
    let bandId: Int

    var storageValue: String {
        "\(festivalDay.rawValue)-\(bandId)"
    }

    init(festivalDay: FestivalDay, bandId: Int) {
        self.festivalDay = festivalDay
        self.bandId = bandId
    }

    init?(storageValue: String) {
        let parts = storageValue.split(separator: "-", maxSplits: 1)
        guard parts.count == 2,
              let day = FestivalDay(rawValue: String(parts[0])),
              let bandId = Int(parts[1]) else {
            return nil
        }
        self.festivalDay = day
        self.bandId = bandId
    }
}

@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var favorites: Set<FavoritePerformanceKey> = []

    private let defaultsKey = "favoritePerformances"

    init() {
        load()
    }

    func isFavorite(day: FestivalDay, bandId: Int) -> Bool {
        favorites.contains(FavoritePerformanceKey(festivalDay: day, bandId: bandId))
    }

    func toggle(day: FestivalDay, bandId: Int) {
        let key = FavoritePerformanceKey(festivalDay: day, bandId: bandId)
        if favorites.contains(key) {
            favorites.remove(key)
        } else {
            favorites.insert(key)
        }
        save()
    }

    private func load() {
        guard let stored = UserDefaults.standard.array(forKey: defaultsKey) as? [String] else {
            return
        }
        favorites = Set(stored.compactMap(FavoritePerformanceKey.init(storageValue:)))
    }

    private func save() {
        let stored = favorites.map(\.storageValue)
        UserDefaults.standard.set(stored, forKey: defaultsKey)
    }
}
