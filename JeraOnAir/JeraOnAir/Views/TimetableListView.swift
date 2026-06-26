import SwiftUI

struct TimetableListView: View {
    let timetable: DayTimetable
    let selectedDay: FestivalDay
    @ObservedObject var favorites: FavoritesStore

    var body: some View {
        List {
            ForEach(timetable.scheduledPerformances) { item in
                PerformanceListRow(
                    bandName: item.performance.name,
                    time: item.performance.time,
                    stageName: item.stageName
                ) {
                    FavoriteButton(
                        favorites: favorites,
                        day: selectedDay,
                        bandId: item.performance.bandId
                    )
                }
                .listRowBackground(JeraTheme.bodyColor2)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(JeraTheme.bodyColor1)
    }
}

struct PerformanceListRow<Trailing: View>: View {
    let bandName: String
    let time: String
    let stageName: String
    @ViewBuilder var trailing: () -> Trailing

    init(
        bandName: String,
        time: String,
        stageName: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.bandName = bandName
        self.time = time
        self.stageName = stageName
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bandName)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .textCase(.uppercase)
                    .foregroundStyle(JeraTheme.textPrimary)

                HStack(spacing: 8) {
                    Text(time)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(JeraTheme.accentGold)

                    Text(stageName)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(JeraTheme.textSecondary)
                }
            }

            Spacer(minLength: 8)

            trailing()
        }
        .padding(.vertical, 4)
    }
}
