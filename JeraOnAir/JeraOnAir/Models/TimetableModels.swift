import Foundation

enum FestivalDay: String, CaseIterable, Identifiable {
    case thu = "THU"
    case fri = "FRI"
    case sat = "SAT"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .thu: "Thu"
        case .fri: "Fri"
        case .sat: "Sat"
        }
    }

    var title: String {
        switch self {
        case .thu: "Thursday"
        case .fri: "Friday"
        case .sat: "Saturday"
        }
    }

    var calendarDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 6
        components.day = switch self {
        case .thu: 25
        case .fri: 26
        case .sat: 27
        }
        components.hour = 0
        components.minute = 0
        components.timeZone = TimeZone(identifier: "Europe/Amsterdam")
        return Calendar(identifier: .gregorian).date(from: components) ?? .now
    }

    static var currentFestivalDay: FestivalDay {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let orderedDays = FestivalDay.allCases
        if today < orderedDays[0].calendarDate {
            return .thu
        }
        if today > orderedDays[2].calendarDate {
            return .sat
        }

        return orderedDays.first(where: { calendar.isDate($0.calendarDate, inSameDayAs: today) }) ?? .thu
    }
}

struct TimetableRoot: Decodable {
    let days: [String: DayTimetable]
}

struct DayTimetable: Decodable {
    let title: String
    let shortTitle: String
    let date: String
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let slotMinutes: Int
    let timeLabels: [TimeLabel]
    let stages: [Stage]

    var gridWidth: CGFloat {
        CGFloat(stages.first?.columnCount ?? 144) * JeraTheme.slotWidth
    }

    func progress(for date: Date = .now) -> Double? {
        let now = date.timeIntervalSince1970
        guard now >= startTimestamp, now <= endTimestamp else { return nil }
        return (now - startTimestamp) / (endTimestamp - startTimestamp)
    }

    func isLive(at date: Date = .now) -> Bool {
        progress(for: date) != nil
    }
}

struct TimeLabel: Decodable, Identifiable {
    let gridColumn: Int
    let label: String

    var id: Int { gridColumn }
}

struct Stage: Decodable, Identifiable {
    let id: String
    let name: String
    let columnCount: Int
    let performances: [Performance]
}

struct Performance: Decodable, Identifiable {
    let bandId: Int
    let name: String
    let time: String
    let gridColumn: Int
    let gridSpan: Int

    var id: Int { bandId }
}

@MainActor
final class TimetableStore: ObservableObject {
    @Published private(set) var days: [FestivalDay: DayTimetable] = [:]
    @Published private(set) var loadError: String?

    init() {
        load()
    }

    func timetable(for day: FestivalDay) -> DayTimetable? {
        days[day]
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "timetable", withExtension: "json") else {
            loadError = "Timetable data not found."
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let root = try JSONDecoder().decode(TimetableRoot.self, from: data)
            var mapped: [FestivalDay: DayTimetable] = [:]
            for festivalDay in FestivalDay.allCases {
                if let day = root.days[festivalDay.rawValue] {
                    mapped[festivalDay] = day
                }
            }
            days = mapped
        } catch {
            loadError = error.localizedDescription
        }
    }
}
