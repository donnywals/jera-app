import SwiftUI

struct TimetableDayContainerView: View {
    let timetable: DayTimetable
    let selectedDay: FestivalDay
    let isCurrentFestivalDay: Bool
    let scrollTrigger: UUID
    @ObservedObject var favorites: FavoritesStore

    @Binding var displayMode: TimetableDisplayMode

    var body: some View {
        VStack(spacing: 0) {
            displayModePicker
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            switch displayMode {
            case .grid:
                TimetableDayView(
                    timetable: timetable,
                    selectedDay: selectedDay,
                    isCurrentFestivalDay: isCurrentFestivalDay,
                    scrollTrigger: scrollTrigger,
                    favorites: favorites
                )
            case .list:
                TimetableListView(
                    timetable: timetable,
                    selectedDay: selectedDay,
                    favorites: favorites
                )
            }
        }
    }

    private var displayModePicker: some View {
        Picker("Display mode", selection: $displayMode) {
            ForEach(TimetableDisplayMode.allCases) { mode in
                Label(mode.title, systemImage: mode.systemImage)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}
