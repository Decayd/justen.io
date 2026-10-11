# Slipstream — F1 stats & widgets for iOS

Slipstream tracks the Formula 1 season (standings, calendar, results and driver/team stats) from
public data, and lets you design Home Screen and Lock Screen widgets in a built-in **Widget Studio**.

## Features

**App**
- **Paddock**: next race hero with live countdown, track map and the weekend schedule in your time zone,
  latest podium, championship table with a points-progression "title fight" chart, constructors.
- **Standings**: drivers and constructors with points bars in team colours, any season back to 1950.
- **Driver & team pages**: wins, podiums, poles, fastest laps, DNFs, average finish, points progression,
  teammate head-to-head and race-by-race results.
- **Calendar**: every round with sprint weekends, winners and a detail page with track map, local
  session times and race / qualifying / sprint classifications.
- **Widget Studio**: build your own widgets: pick what they show, a style (Auto, Carbon, Paper, Glow
  or full team Livery), an accent colour and options, and preview them live at real size in dark, light
  and tinted appearances.

**Widgets** (every widget supports Small, Medium, Large, iPad Extra Large and the Lock Screen
circular, rectangular and inline sizes)

| Widget | What it shows |
| --- | --- |
| Next Race | Countdown, circuit map, round, sprint badge and the full session schedule |
| Calendar | The next rounds with dates, a season progress bar and sprint markers |
| Drivers' Standings | Leader card, top 5 with bars, or the top 10 with gaps and points still available |
| Constructors' Standings | Team order with each team's drivers and points bars |
| Race Result | Podium blocks in team colours, classification, positions gained and the fastest lap |
| Driver | Your driver: position, points, gap, wins, podiums, poles, recent form and a progression chart |
| Team | Your team: position, points split between its drivers, form and a chart against its rivals |
| Title Fight | Points progression of the contenders, the gap, and the maximum each can still reach |
| My Widgets | Any design you built in the Widget Studio (long-press the widget → Edit to choose it) |

Widgets refresh on a schedule that tightens around race weekends and chases new results after each
session. Countdowns tick over exactly on the hour (and run a live timer in the final hour), and
widgets render correctly in tinted / clear Home Screens and on the Lock Screen.

## Data sources

- [Jolpica-F1](https://github.com/jolpica/jolpica-f1): the open-source, Ergast-compatible F1 API
  (schedule, standings, race / sprint / qualifying results). Requests are paced and cached in the shared
  App Group container so the app and widgets stay well within the API's rate limits.
- [bacinger/f1-circuits](https://github.com/bacinger/f1-circuits) (MIT): circuit outlines, converted
  into `Shared/Resources/circuits.json` by `tools/build_circuits.py`.
- Team colours follow the broadcast colours published in FastF1's constants.

Until the first download finishes, widget previews use an illustrative sample season
(`Shared/Studio/SampleData.swift`): made-up results on the 2026 grid, never shown as real data.

## Project layout

```
Slipstream.xcodeproj   Xcode 16+ project (folders are synchronized, so new files are picked up automatically)
App/                   SwiftUI app: Paddock, Standings, Calendar, Widget Studio, Settings
Widgets/               WidgetKit extension: widget kinds, timeline providers, App Intents
Shared/                Code compiled into both targets
  Core/                Models, Jolpica client, snapshot cache, stats, scheduling
  Design/              Theme, typography, team colours, flags, track maps, components
  Studio/              Widget designs, settings, sample data
  WidgetViews/         Every widget layout for every size
Tests/                 Unit tests plus a snapshot test that renders every widget to PNG
Config/                Info.plists and entitlements
tools/                 Scripts that generate circuits.json and the app icon
```

## Running it

1. Open `Slipstream.xcodeproj` in Xcode 16 or newer.
2. Select the **Slipstream** target → *Signing & Capabilities*, choose your team, and make sure the
   **App Groups** capability lists `group.io.justen.slipstream` (change the bundle IDs and group if
   that ID is taken; the group ID is also defined in `Shared/Core/SharedStorage.swift`).
3. Do the same for the **SlipstreamWidgets** target.
4. Run on a device or simulator. To try a widget directly, run the **SlipstreamWidgets** scheme.

Requires iOS 18 or later.

## Tests and widget snapshots

`xcodebuild test -project Slipstream.xcodeproj -scheme Slipstream -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`

`WidgetSnapshotTests` renders every widget in every size to PNG contact sheets. Set
`TEST_RUNNER_SNAPSHOT_DIR=/some/folder` to choose where they're written. The GitHub Actions workflow
(`.github/workflows/slipstream-ios.yml`) builds the app, runs the tests and uploads the snapshots.

Slipstream is unofficial and not associated with the Formula 1 companies.
