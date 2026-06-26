# Jera On Air Timetable

A simple iOS app that shows the [Jera On Air 2026](https://www.jeraonair.nl/nl/timetable/) festival timetable for Thursday, Friday, and Saturday.

## Screenshots

Captured on iPhone 17 Pro Max simulator.

| Grid (stage sections) | List (by start time) | Favorites |
| --- | --- | --- |
| ![Grid layout](docs/screenshots/grid-layout.png) | ![List view](docs/screenshots/list-view.png) | ![Favorites](docs/screenshots/favorites.png) |

## Features

- Day tabs (THU / FRI / SAT) styled like the festival website
- Grid view with stage names as section headers and horizontal timelines underneath
- List view sorted by band start time, with stage name on each row
- Star favorites persisted between launches
- Bottom tab bar with Timetable and Favorites screens
- Red current-time marker during live festival hours
- Automatically selects today's festival day when you open the app
- Automatically scrolls horizontally to the current time on the active day

## Open in Xcode

```bash
open JeraOnAir/JeraOnAir.xcodeproj
```

Select an iPhone simulator or your device, then run.

You can also build and run with [FlowDeck](https://docs.flowdeck.studio/cli):

```bash
cd JeraOnAir
flowdeck run -w JeraOnAir.xcodeproj -s JeraOnAir -S "iPhone 17 Pro Max"
```

## Update timetable data

The app ships with bundled timetable JSON scraped from jeraonair.nl. To refresh it:

```bash
python3 JeraOnAir/Scripts/update_timetable.py
```

Then rebuild the app in Xcode.

## Project layout

- `JeraOnAir/JeraOnAirApp.swift` — app entry point
- `JeraOnAir/ContentView.swift` — tab bar and day selection
- `JeraOnAir/Views/TimetableDayView.swift` — grid timetable with stage sections
- `JeraOnAir/Views/TimetableListView.swift` — chronological list view
- `JeraOnAir/Views/FavoritesView.swift` — favorited bands list
- `JeraOnAir/Models/TimetableModels.swift` — data models and loader
- `JeraOnAir/Models/FavoritesStore.swift` — favorite persistence
- `JeraOnAir/timetable.json` — bundled timetable for all three days
