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

    private var visibleTimeLabels: [TimeLabel] {
        timetable.timeLabels.filter { label in
            !(label.gridColumn == timetable.timeLabels.first?.gridColumn ||
              label.gridColumn == timetable.timeLabels.last?.gridColumn)
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text(timetable.title)
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(JeraTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                GeometryReader { geo in
                    HStack(spacing: 0) {
                        stageLabelsColumn(maxWidth: geo.size.width * 0.25)

                        ScrollView(.horizontal, showsIndicators: true) {
                            ZStack(alignment: .topLeading) {
                                VStack(spacing: 0) {
                                    timeHeader
                                    stageRows
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
                    }
                }
                .frame(height: timelineHeight)
                .padding(.horizontal, 12)

                Text("Times are subject to change. Keep an eye on jeraonair.nl for updates.")
                    .font(.caption2)
                    .foregroundStyle(JeraTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 16)
            }
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

    private var timelineHeight: CGFloat {
        JeraTheme.timeHeaderHeight + CGFloat(timetable.stages.count) * JeraTheme.stageHeight
    }

    private func stageLabelsColumn(maxWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: JeraTheme.timeHeaderHeight)

            ForEach(timetable.stages) { stage in
                Text(stage.name)
                    .font(.system(.caption2, design: .rounded, weight: .heavy))
                    .textCase(.uppercase)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(JeraTheme.textPrimary)
                    .shadow(color: JeraTheme.bodyColor1, radius: 6)
                    .frame(maxWidth: maxWidth)
                    .frame(height: JeraTheme.stageHeight)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .padding(.trailing, 4)
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

    private var stageRows: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 0) {
                ForEach(timetable.stages) { stage in
                    stageRowBackground
                }
            }

            VStack(spacing: 0) {
                ForEach(timetable.stages) { stage in
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
        }
    }

    private var stageRowBackground: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .fill(JeraTheme.bodyColor2)
                .frame(height: JeraTheme.stageHeight)

            HStack(spacing: 0) {
                ForEach(0..<(timetable.stages.first?.columnCount ?? 144), id: \.self) { index in
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
            VStack(alignment: .leading, spacing: 2) {
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
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(width: max(width, 88), alignment: .leading)
            .frame(maxHeight: JeraTheme.stageHeight * 0.85)
            .background(JeraTheme.accentGold)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 8, y: 2)

            FavoriteButton(
                favorites: favorites,
                day: selectedDay,
                bandId: performance.bandId,
                iconSize: 12,
                favoriteColor: .black
            )
            .padding(2)
        }
        .offset(x: x + 2, y: JeraTheme.stageHeight * 0.075)
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
