import Foundation

enum FestivalDay: String, CaseIterable, Identifiable, Codable {
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

    var scheduledPerformances: [ScheduledPerformance] {
        stages.flatMap { stage in
            stage.performances.map { performance in
                ScheduledPerformance(
                    stageID: stage.id,
                    stageName: stage.name,
                    performance: performance
                )
            }
        }
        .sorted { lhs, rhs in
            let leftStart = lhs.startDate(in: self)
            let rightStart = rhs.startDate(in: self)
            if leftStart != rightStart {
                return leftStart < rightStart
            }
            if lhs.stageName != rhs.stageName {
                return lhs.stageName.localizedStandardCompare(rhs.stageName) == .orderedAscending
            }
            return lhs.performance.name.localizedStandardCompare(rhs.performance.name) == .orderedAscending
        }
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

struct Performance: Decodable, Identifiable, Hashable {
    let bandId: Int
    let name: String
    let time: String
    let gridColumn: Int
    let gridSpan: Int

    var id: String { "\(bandId)-\(gridColumn)" }

    func startDate(in timetable: DayTimetable) -> Date {
        let offsetSeconds = Double((gridColumn - 1) * timetable.slotMinutes * 60)
        return Date(timeIntervalSince1970: timetable.startTimestamp + offsetSeconds)
    }
}

struct ScheduledPerformance: Identifiable, Hashable {
    let stageID: String
    let stageName: String
    let performance: Performance

    var id: String { "\(stageID)-\(performance.bandId)-\(performance.gridColumn)" }

    func startDate(in timetable: DayTimetable) -> Date {
        performance.startDate(in: timetable)
    }
}

enum TimetableDisplayMode: String, CaseIterable, Identifiable {
    case grid
    case list

    var id: String { rawValue }

    var title: String {
        switch self {
        case .grid: "Grid"
        case .list: "List"
        }
    }

    var systemImage: String {
        switch self {
        case .grid: "calendar.day.timeline.left"
        case .list: "list.bullet"
        }
    }
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
