import SwiftUI

struct TimetableDayView: View {
    let timetable: DayTimetable
    let selectedDay: FestivalDay
    let isCurrentFestivalDay: Bool
    let scrollTrigger: UUID
    @ObservedObject var favorites: FavoritesStore

    @State private var now = Date()
    @State private var didInitialScroll = false
    @State private var timelineScrollID: String?

    private let scrollAnchorID = "current-time-anchor"

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                Text(timetable.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(JeraTheme.textPrimary)
                    .padding(.horizontal, 16)

                ForEach(timetable.stages) { stage in
                    stageSection(stage)
                }

                Text("Times are subject to change. Keep an eye on jeraonair.nl for updates.")
                    .font(.caption2)
                    .foregroundStyle(JeraTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            .padding(.top, 4)
        }
        .onAppear(perform: scheduleInitialScroll)
        .onChange(of: selectedDay) { _, _ in
            didInitialScroll = false
            scheduleInitialScroll()
        }
        .onChange(of: scrollTrigger) { _, _ in
            didInitialScroll = false
            scheduleInitialScroll()
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }

    private func stageSection(_ stage: Stage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(stage.name)
                .font(.system(.headline, design: .rounded, weight: .heavy))
                .textCase(.uppercase)
                .foregroundStyle(JeraTheme.textPrimary)
                .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: true) {
                ZStack(alignment: .topLeading) {
                    VStack(spacing: 0) {
                        timeHeader
                        stageRow(for: stage)
                    }
                    .frame(width: timetable.gridWidth)

                    if isCurrentFestivalDay, let progress = timetable.progress(for: now) {
                        currentTimeIndicator(progress: progress)
                    }
                }
            }
            .scrollPosition(id: $timelineScrollID, anchor: .center)
            .background(JeraTheme.bodyColor2)
            .clipShape(RoundedRectangle(cornerRadius: JeraTheme.cornerRadius, style: .continuous))
            .padding(.horizontal, 12)
        }
    }

    private var visibleTimeLabels: [TimeLabel] {
        timetable.timeLabels.filter { label in
            !(label.gridColumn == timetable.timeLabels.first?.gridColumn ||
              label.gridColumn == timetable.timeLabels.last?.gridColumn)
        }
    }

    private var timeHeader: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(height: JeraTheme.timeHeaderHeight)

            ForEach(visibleTimeLabels) { label in
                Text(label.label)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(JeraTheme.textSecondary)
                    .frame(width: 50)
                    .offset(x: xOffset(for: label.gridColumn) - 25, y: 8)
            }
        }
        .frame(height: JeraTheme.timeHeaderHeight)
    }

    private func stageRow(for stage: Stage) -> some View {
        ZStack(alignment: .leading) {
            stageRowBackground(columnCount: stage.columnCount)

            ZStack(alignment: .leading) {
                Color.clear
                    .frame(height: JeraTheme.stageHeight)

                ForEach(stage.performances) { performance in
                    performanceBlock(performance)
                }
            }
            .frame(height: JeraTheme.stageHeight)
        }
    }

    private func stageRowBackground(columnCount: Int) -> some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(JeraTheme.bodyColor2)
                .frame(height: JeraTheme.stageHeight)

            HStack(spacing: 0) {
                ForEach(0..<columnCount, id: \.self) { index in
                    Rectangle()
                        .fill(JeraTheme.bodyColor1.opacity(index.isMultiple(of: 2) ? 0.35 : 0.15))
                        .frame(width: index.isMultiple(of: 12) ? 2 : 1)
                }
            }
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(JeraTheme.bodyColor1)
                .frame(height: 3)
        }
    }

    private func performanceBlock(_ performance: Performance) -> some View {
        let width = CGFloat(performance.gridSpan) * JeraTheme.slotWidth
        let x = xOffset(for: performance.gridColumn)

        return ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 4) {
                Text(performance.name)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                    .foregroundStyle(JeraTheme.bodyColor1)

                Text(performance.time)
                    .font(.system(.caption2, design: .monospaced))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(JeraTheme.bodyColor1.opacity(0.85))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(width: max(width - 4, 56), alignment: .leading)
            .frame(maxHeight: JeraTheme.stageHeight * 0.8)
            .background(JeraTheme.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 2)

            FavoriteButton(
                favorites: favorites,
                day: selectedDay,
                bandId: performance.bandId
            )
            .padding(4)
        }
        .offset(x: x + 2, y: JeraTheme.stageHeight * 0.1)
    }

    private func currentTimeIndicator(progress: Double) -> some View {
        Rectangle()
            .fill(JeraTheme.currentTimeLine)
            .frame(width: 2)
            .frame(maxHeight: .infinity)
            .shadow(color: .red.opacity(0.45), radius: 6)
            .offset(x: timetable.gridWidth * progress)
            .id(scrollAnchorID)
            .allowsHitTesting(false)
    }

    private func xOffset(for gridColumn: Int) -> CGFloat {
        CGFloat(gridColumn - 1) * JeraTheme.slotWidth
    }

    private func scheduleInitialScroll() {
        guard !didInitialScroll else { return }
        guard isCurrentFestivalDay, timetable.isLive(at: now) else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            timelineScrollID = scrollAnchorID
            didInitialScroll = true
        }
    }
}
