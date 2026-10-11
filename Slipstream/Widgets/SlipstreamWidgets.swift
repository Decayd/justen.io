import SwiftUI
import WidgetKit

@main
struct SlipstreamWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextRaceWidget()
        DriverStandingsWidget()
        ConstructorStandingsWidget()
        RaceResultWidget()
        DriverWidget()
        TeamWidget()
        TitleFightWidget()
        CalendarWidget()
        StudioWidget()
    }
}

private let homeFamilies: [WidgetFamily] = [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
private let lockFamilies: [WidgetFamily] = [.accessoryCircular, .accessoryRectangular, .accessoryInline]

/// A ready-made design that follows the app's default style.
private func preset(_ content: WidgetContent, driverId: String? = nil, constructorId: String? = nil) -> WidgetDesign {
    let settings = AppSettings.load()
    return WidgetDesign(
        content: content,
        theme: content.supportsLivery ? .team : settings.defaultTheme,
        accent: content.supportsLivery ? .team : settings.defaultAccent,
        driverId: driverId,
        constructorId: constructorId
    )
}

// MARK: - Static widgets

struct PresetProvider: TimelineProvider {
    let content: WidgetContent

    func placeholder(in context: Context) -> SlipstreamEntry {
        TimelineFactory.placeholder(design: WidgetDesign(content: content))
    }

    func getSnapshot(in context: Context, completion: @escaping (SlipstreamEntry) -> Void) {
        let design = preset(content)
        let isPreview = context.isPreview
        Task {
            completion(await TimelineFactory.preview(design: design, isPreview: isPreview))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SlipstreamEntry>) -> Void) {
        let design = preset(content)
        Task {
            completion(await TimelineFactory.timeline(design: design))
        }
    }
}

struct NextRaceWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NextRace", provider: PresetProvider(content: .nextRace)) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Race")
        .description("Countdown, track map and the full weekend schedule in your time zone.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct DriverStandingsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "DriverStandings", provider: PresetProvider(content: .driverStandings)) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Drivers' Standings")
        .description("The championship order with points bars in team colours.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct ConstructorStandingsWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ConstructorStandings", provider: PresetProvider(content: .constructorStandings)) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Constructors' Standings")
        .description("Team standings and how each team's points split between its drivers.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct RaceResultWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "RaceResult", provider: PresetProvider(content: .lastRace)) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Race Result")
        .description("The podium, classification and fastest lap from the latest Grand Prix.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct TitleFightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TitleFight", provider: PresetProvider(content: .titleFight)) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Title Fight")
        .description("How the contenders' points have evolved, and what's still possible.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct CalendarWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Calendar", provider: PresetProvider(content: .calendar)) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("The next rounds at a glance, with sprint weekends marked.")
        .supportedFamilies(homeFamilies + [.accessoryCircular, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Configurable widgets

struct DriverProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SlipstreamEntry {
        TimelineFactory.placeholder(design: WidgetDesign(content: .driver))
    }

    func snapshot(for configuration: DriverWidgetIntent, in context: Context) async -> SlipstreamEntry {
        await TimelineFactory.preview(design: preset(.driver, driverId: configuration.driver?.id), isPreview: context.isPreview)
    }

    func timeline(for configuration: DriverWidgetIntent, in context: Context) async -> Timeline<SlipstreamEntry> {
        await TimelineFactory.timeline(design: preset(.driver, driverId: configuration.driver?.id))
    }
}

struct DriverWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "Driver", intent: DriverWidgetIntent.self, provider: DriverProvider()) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Driver")
        .description("Your driver's position, points, wins, podiums and recent form.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct TeamProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SlipstreamEntry {
        TimelineFactory.placeholder(design: WidgetDesign(content: .team))
    }

    func snapshot(for configuration: TeamWidgetIntent, in context: Context) async -> SlipstreamEntry {
        await TimelineFactory.preview(design: preset(.team, constructorId: configuration.team?.id), isPreview: context.isPreview)
    }

    func timeline(for configuration: TeamWidgetIntent, in context: Context) async -> Timeline<SlipstreamEntry> {
        await TimelineFactory.timeline(design: preset(.team, constructorId: configuration.team?.id))
    }
}

struct TeamWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "Team", intent: TeamWidgetIntent.self, provider: TeamProvider()) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("Team")
        .description("Your team's position, points and how its drivers compare.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}

struct StudioProvider: AppIntentTimelineProvider {
    private func design(for configuration: StudioWidgetIntent) -> WidgetDesign {
        if let id = configuration.design?.id, let design = DesignStore.design(id: id) {
            return design
        }
        return DesignStore.load().first ?? preset(.nextRace)
    }

    func placeholder(in context: Context) -> SlipstreamEntry {
        TimelineFactory.placeholder(design: WidgetDesign(content: .nextRace))
    }

    func snapshot(for configuration: StudioWidgetIntent, in context: Context) async -> SlipstreamEntry {
        await TimelineFactory.preview(design: design(for: configuration), isPreview: context.isPreview)
    }

    func timeline(for configuration: StudioWidgetIntent, in context: Context) async -> Timeline<SlipstreamEntry> {
        await TimelineFactory.timeline(design: design(for: configuration))
    }
}

struct StudioWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "Studio", intent: StudioWidgetIntent.self, provider: StudioProvider()) { entry in
            SlipstreamWidgetView(entry: entry)
        }
        .configurationDisplayName("My Widgets")
        .description("Any widget you designed in the Widget Studio. Edit the widget to pick a design.")
        .supportedFamilies(homeFamilies + lockFamilies)
        .contentMarginsDisabled()
    }
}
