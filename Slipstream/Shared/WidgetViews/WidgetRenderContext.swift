import SwiftUI

/// Everything a widget view needs to draw itself.
struct WidgetRenderContext {
    var snapshot: SeasonSnapshot
    var stats: SeasonStats
    var design: WidgetDesign
    var size: WidgetSize
    var now: Date
    var palette: WidgetPalette
    /// The driver this widget is about (selected, favourite, or championship leader).
    var driver: DriverStanding?
    /// The team this widget is about (selected, favourite, or championship leader).
    var team: ConstructorStanding?

    var season: Int { snapshot.standingsSeason }

    var showFlags: Bool { design.showFlags }

    func teamRGB(_ constructorId: String?) -> RGB {
        TeamPalette.rgb(for: constructorId, season: season)
    }

    func teamColor(_ constructorId: String?) -> Color {
        palette.team(teamRGB(constructorId))
    }

    func flag(for race: Race) -> String {
        Flags.country(race.circuit.country)
    }

    static func make(
        design: WidgetDesign,
        snapshot: SeasonSnapshot,
        stats: SeasonStats? = nil,
        size: WidgetSize,
        now: Date,
        renderStyle: RenderStyle,
        colorScheme: ColorScheme,
        settings: AppSettings
    ) -> WidgetRenderContext {
        let driverId = design.driverId ?? settings.favoriteDriverId
        let driver = driverId.flatMap { snapshot.driverStanding(id: $0) } ?? snapshot.driverStandings.first

        let teamId: String?
        if design.content == .driver {
            teamId = driver?.constructor?.id
        } else {
            teamId = design.constructorId ?? settings.favoriteTeamId
        }
        let team = teamId.flatMap { snapshot.constructorStanding(id: $0) } ?? snapshot.constructorStandings.first

        let subjectTeamId: String?
        switch design.content {
        case .driver: subjectTeamId = driver?.constructor?.id
        case .team: subjectTeamId = team?.constructor.id
        default: subjectTeamId = team?.constructor.id ?? driver?.constructor?.id
        }
        let teamRGB = subjectTeamId.map { TeamPalette.rgb(for: $0, season: snapshot.standingsSeason) }

        // The livery theme only makes sense for single-subject widgets.
        let theme: WidgetTheme = (design.theme == .team && !design.content.supportsLivery) ? .glow : design.theme
        let palette = WidgetPalette.resolve(
            theme: theme,
            accent: design.accent,
            teamRGB: teamRGB,
            colorScheme: colorScheme,
            renderStyle: size.isAccessory ? .vibrant : renderStyle
        )

        return WidgetRenderContext(
            snapshot: snapshot,
            stats: stats ?? SeasonStats(snapshot: snapshot),
            design: design,
            size: size,
            now: now,
            palette: palette,
            driver: driver,
            team: team
        )
    }
}

/// Picks the right layout for a design's content.
struct WidgetContentView: View {
    let context: WidgetRenderContext

    var body: some View {
        content
            .environment(\.palette, context.palette)
    }

    @ViewBuilder
    private var content: some View {
        switch context.design.content {
        case .nextRace: NextRaceWidgetView(context: context)
        case .calendar: CalendarWidgetView(context: context)
        case .driverStandings: DriverStandingsWidgetView(context: context)
        case .constructorStandings: ConstructorStandingsWidgetView(context: context)
        case .lastRace: LastRaceWidgetView(context: context)
        case .driver: DriverWidgetView(context: context)
        case .team: TeamWidgetView(context: context)
        case .titleFight: TitleFightWidgetView(context: context)
        }
    }
}

/// Applies the home screen padding we use instead of system content margins,
/// so in-app previews match the real widget exactly.
struct WidgetPadding: ViewModifier {
    let size: WidgetSize

    func body(content: Content) -> some View {
        content
            .padding(size.padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

extension View {
    func widgetPadding(_ size: WidgetSize) -> some View {
        modifier(WidgetPadding(size: size))
    }
}

/// Shown when no data has been downloaded yet.
struct NoDataView: View {
    let size: WidgetSize
    @Environment(\.palette) private var palette

    var body: some View {
        switch size {
        case .inline:
            Text("Open Slipstream to load F1 data")
        case .circular:
            ZStack {
                AccessoryCircleBackground()
                Image(systemName: "flag.checkered").font(.system(size: 22, weight: .semibold))
            }
        case .rectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("SLIPSTREAM").font(Typo.label(11, weight: .heavy))
                Text("Open the app to load F1 data").font(Typo.text(12)).lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        default:
            WidgetMessage(symbol: "flag.checkered", title: "No data yet", message: "Open Slipstream to download the latest standings.")
                .widgetPadding(size)
        }
    }
}
