import SwiftUI

struct TimetableListView: View {
    let timetable: DayTimetable

    var body: some View {
        List {
            ForEach(timetable.scheduledPerformances) { item in
                PerformanceListRow(
                    bandName: item.performance.name,
                    time: item.performance.time,
                    stageName: item.stageName
                )
                .listRowBackground(JeraTheme.bodyColor2)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(JeraTheme.bodyColor1)
    }
}

struct PerformanceListRow: View {
    let bandName: String
    let time: String
    let stageName: String
    var trailingContent: AnyView?

    init(
        bandName: String,
        time: String,
        stageName: String,
        trailingContent: AnyView? = nil
    ) {
        self.bandName = bandName
        self.time = time
        self.stageName = stageName
        self.trailingContent = trailingContent
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

            if let trailingContent {
                trailingContent
            }
        }
        .padding(.vertical, 4)
    }
}
