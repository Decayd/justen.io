import SwiftUI
import WidgetKit

// MARK: - Shared row model

/// A normalised standings row so drivers and constructors share layouts.
struct StandingsLine: Identifiable, Hashable {
    var id: String
    var position: Int
    var title: String
    var code: String
    var subtitle: String
    var flag: String
    var points: Double
    var wins: Int
    var team: RGB

    static func drivers(_ context: WidgetRenderContext) -> [StandingsLine] {
        context.snapshot.driverStandings.map { standing in
            StandingsLine(
                id: standing.driver.id,
                position: standing.position,
                title: standing.driver.familyName,
                code: standing.driver.code,
                subtitle: standing.constructor.map(TeamPalette.shortName) ?? "",
                flag: Flags.nationality(standing.driver.nationality),
                points: standing.points,
                wins: standing.wins,
                team: context.teamRGB(standing.constructor?.id)
            )
        }
    }

    static func constructors(_ context: WidgetRenderContext) -> [StandingsLine] {
        context.snapshot.constructorStandings.map { standing in
            let drivers = context.snapshot.drivers(of: standing.constructor.id).prefix(2).map(\.driver.code)
            return StandingsLine(
                id: standing.constructor.id,
                position: standing.position,
                title: TeamPalette.shortName(for: standing.constructor),
                code: TeamPalette.code(for: standing.constructor),
                subtitle: drivers.joined(separator: " · "),
                flag: Flags.nationality(standing.constructor.nationality),
                points: standing.points,
                wins: standing.wins,
                team: context.teamRGB(standing.constructor.id)
            )
        }
    }
}

struct DriverStandingsWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        StandingsWidget(context: context, lines: StandingsLine.drivers(context), title: "Drivers", isTeams: false)
    }
}

struct ConstructorStandingsWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        StandingsWidget(context: context, lines: StandingsLine.constructors(context), title: "Constructors", isTeams: true)
    }
}

private struct StandingsWidget: View {
    let context: WidgetRenderContext
    let lines: [StandingsLine]
    let title: String
    let isTeams: Bool

    var body: some View {
        if lines.isEmpty {
            NoStandingsView(context: context)
        } else {
            switch context.size {
            case .small: StandingsSmall(context: context, lines: lines, title: title, isTeams: isTeams)
            case .medium: StandingsMedium(context: context, lines: lines, title: title, isTeams: isTeams)
            case .large: StandingsLarge(context: context, lines: lines, title: title, isTeams: isTeams)
            case .extraLarge: StandingsExtraLarge(context: context, lines: lines, title: title, isTeams: isTeams)
            case .circular: StandingsCircular(lines: lines)
            case .rectangular: StandingsRectangular(lines: lines, title: title, isTeams: isTeams)
            case .inline: StandingsInline(lines: lines)
            }
        }
    }
}

/// "DRIVERS · AFTER R19" header used by all home screen sizes.
private struct StandingsHeader: View {
    let context: WidgetRenderContext
    let title: String
    var compact = false
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            CapsLabel(title, size: 9, color: palette.secondary)
            Spacer(minLength: 0)
            if let race = context.snapshot.standingsRace(round: context.snapshot.standingsRound), !compact {
                if context.showFlags { FlagText(flag: Flags.country(race.circuit.country), size: 10) }
                CapsLabel("After \(race.shortName)", size: 8, color: palette.tertiary)
            } else {
                CapsLabel("R\(context.snapshot.standingsRound)/\(context.snapshot.totalRounds)", size: 8.5, color: palette.tertiary)
            }
        }
    }
}

// MARK: - Small: leader card + two chasers

private struct StandingsSmall: View {
    let context: WidgetRenderContext
    let lines: [StandingsLine]
    let title: String
    let isTeams: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StandingsHeader(context: context, title: title, compact: true)
            Spacer(minLength: 6)
            VStack(spacing: 7) {
                ForEach(lines.prefix(3)) { line in
                    row(line)
                }
            }
            Spacer(minLength: 0)
        }
        .widgetPadding(.small)
    }

    private func row(_ line: StandingsLine) -> some View {
        let isLeader = line.position == 1
        let gap = line.points - (lines.first?.points ?? 0)
        return HStack(spacing: 7) {
            Text("\(line.position)")
                .font(Typo.number(10, weight: .heavy))
                .foregroundStyle(palette.tertiary)
                .frame(width: 10, alignment: .leading)
            TeamStripe(color: palette.team(line.team), width: 3.5, height: isLeader ? 30 : 24)
            VStack(alignment: .leading, spacing: 0) {
                Text(isTeams ? line.title.uppercased() : line.code)
                    .font(isTeams ? Typo.display(isLeader ? 12 : 10.5, weight: .heavy) : Typo.display(isLeader ? 17 : 14, weight: .heavy))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.55)
                Text(line.subtitle)
                    .font(Typo.text(8.5, weight: .medium))
                    .foregroundStyle(palette.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 0) {
                Text(Fmt.points(line.points))
                    .font(Typo.number(isLeader ? 15 : 13, weight: .heavy))
                    .foregroundStyle(palette.primary)
                Text(isLeader ? "PTS" : Fmt.gap(gap))
                    .font(Typo.number(8.5, weight: .bold))
                    .foregroundStyle(isLeader ? palette.tertiary : palette.secondary)
            }
        }
    }
}

// MARK: - Medium: top five with points bars

private struct StandingsMedium: View {
    let context: WidgetRenderContext
    let lines: [StandingsLine]
    let title: String
    let isTeams: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StandingsHeader(context: context, title: title)
            Spacer(minLength: 6)
            VStack(spacing: 0) {
                ForEach(lines.prefix(5)) { line in
                    BarRow(line: line, leaderPoints: lines.first?.points ?? 1, isTeams: isTeams, showGap: false, compact: true)
                        .frame(maxHeight: .infinity)
                }
            }
        }
        .widgetPadding(.medium)
    }
}

/// A standings row with a points bar in team colours.
private struct BarRow: View {
    let line: StandingsLine
    let leaderPoints: Double
    let isTeams: Bool
    var showGap = true
    var compact = false
    var showSubtitle = false
    var showFlag = false
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 7) {
            if compact {
                Text("\(line.position)")
                    .font(Typo.number(10, weight: .heavy))
                    .foregroundStyle(palette.tertiary)
                    .frame(width: 14, alignment: .leading)
            } else {
                PositionBadge(position: line.position, size: 18)
            }
            TeamStripe(color: palette.team(line.team), width: 3, height: compact ? 14 : 18)
            nameBlock
                .frame(width: nameWidth, alignment: .leading)
            PointsBar(fraction: leaderPoints > 0 ? line.points / leaderPoints : 0, color: palette.team(line.team), height: compact ? 5 : 6)
            Text(Fmt.points(line.points))
                .font(Typo.number(compact ? 12 : 12.5, weight: .heavy))
                .foregroundStyle(palette.primary)
                .frame(width: 32, alignment: .trailing)
            if showGap {
                Text(line.position == 1 ? "" : Fmt.gap(line.points - leaderPoints))
                    .font(Typo.number(9.5, weight: .semibold))
                    .foregroundStyle(palette.tertiary)
                    .frame(width: 32, alignment: .trailing)
            }
        }
    }

    private var nameWidth: CGFloat {
        if isTeams { return showSubtitle ? 90 : 86 }
        return showSubtitle ? 88 : 38
    }

    @ViewBuilder
    private var nameBlock: some View {
        if showSubtitle {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    if showFlag && !isTeams { Text(line.flag).font(.system(size: 10)) }
                    Text(isTeams ? line.title : line.title.uppercased())
                        .font(isTeams ? Typo.text(12, weight: .bold) : Typo.display(10.5, weight: .heavy))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Text(line.subtitle)
                    .font(Typo.text(8.5, weight: .medium))
                    .foregroundStyle(palette.tertiary)
                    .lineLimit(1)
            }
        } else {
            Text(isTeams ? line.title : line.code)
                .font(isTeams ? Typo.text(11.5, weight: .bold) : Typo.code(13, weight: .heavy))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }
}

// MARK: - Large: top ten

private struct StandingsLarge: View {
    let context: WidgetRenderContext
    let lines: [StandingsLine]
    let title: String
    let isTeams: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StandingsHeader(context: context, title: isTeams ? "Constructors' Championship" : "Drivers' Championship")
            Spacer(minLength: 8)
            VStack(spacing: 0) {
                ForEach(lines.prefix(10)) { line in
                    BarRow(line: line, leaderPoints: lines.first?.points ?? 1, isTeams: isTeams, showSubtitle: true, showFlag: context.showFlags)
                        .frame(maxHeight: .infinity)
                }
            }
            Rectangle().fill(palette.hairline).frame(height: 1).padding(.vertical, 7)
            ChampionshipFooter(context: context, isTeams: isTeams)
        }
        .widgetPadding(.large)
    }
}

private struct ChampionshipFooter: View {
    let context: WidgetRenderContext
    let isTeams: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        let remaining = context.snapshot.remainingRaces.count
        let available = isTeams ? context.snapshot.maxConstructorPointsRemaining : context.snapshot.maxPointsRemaining
        HStack(spacing: 6) {
            Image(systemName: remaining == 0 ? "trophy.fill" : "flag.checkered")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(palette.accent)
                .widgetAccentable()
            if remaining == 0 {
                Text("Final standings")
                    .font(Typo.text(10.5, weight: .semibold))
                    .foregroundStyle(palette.secondary)
            } else {
                Text("\(remaining) \(remaining == 1 ? "race" : "races") left")
                    .font(Typo.text(10.5, weight: .semibold))
                    .foregroundStyle(palette.secondary)
                Text("·").foregroundStyle(palette.tertiary)
                Text("up to \(Fmt.points(available.rounded())) pts available")
                    .font(Typo.text(10.5, weight: .medium))
                    .foregroundStyle(palette.tertiary)
            }
            Spacer(minLength: 0)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

// MARK: - Extra large: full grid in two columns

private struct StandingsExtraLarge: View {
    let context: WidgetRenderContext
    let lines: [StandingsLine]
    let title: String
    let isTeams: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        let half = Int((Double(min(lines.count, 22)) / 2).rounded(.up))
        VStack(alignment: .leading, spacing: 0) {
            StandingsHeader(context: context, title: isTeams ? "Constructors' Championship" : "Drivers' Championship")
            Spacer(minLength: 8)
            HStack(alignment: .top, spacing: 18) {
                column(Array(lines.prefix(half)))
                column(Array(lines.dropFirst(half).prefix(half)))
            }
            Rectangle().fill(palette.hairline).frame(height: 1).padding(.vertical, 6)
            ChampionshipFooter(context: context, isTeams: isTeams)
        }
        .widgetPadding(.extraLarge)
    }

    private func column(_ items: [StandingsLine]) -> some View {
        VStack(spacing: 0) {
            ForEach(items) { line in
                BarRow(line: line, leaderPoints: lines.first?.points ?? 1, isTeams: isTeams, showSubtitle: true, showFlag: context.showFlags)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Lock Screen

private struct StandingsCircular: View {
    let lines: [StandingsLine]

    var body: some View {
        let leader = lines[0]
        let gap = lines.count > 1 ? leader.points - lines[1].points : 0
        ZStack {
            AccessoryCircleBackground()
            VStack(spacing: -1) {
                Text("P1").font(Typo.label(7, weight: .heavy)).opacity(0.75)
                Text(leader.code).font(Typo.display(14, weight: .heavy)).minimumScaleFactor(0.6)
                Text("+\(Fmt.points(gap))").font(Typo.number(9, weight: .bold)).opacity(0.8)
            }
            .widgetAccentable()
        }
    }
}

private struct StandingsRectangular: View {
    let lines: [StandingsLine]
    let title: String
    let isTeams: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(lines.prefix(3)) { line in
                HStack(spacing: 5) {
                    Text("\(line.position)")
                        .font(Typo.number(11, weight: .heavy))
                        .frame(width: 10, alignment: .leading)
                        .opacity(0.7)
                    Text(isTeams ? line.title : line.code)
                        .font(isTeams ? Typo.text(12.5, weight: .bold) : Typo.display(12, weight: .heavy))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 2)
                    Text(Fmt.points(line.points))
                        .font(Typo.number(12.5, weight: .bold))
                }
                .widgetAccentable(line.position == 1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct StandingsInline: View {
    let lines: [StandingsLine]

    var body: some View {
        let top = lines.prefix(2).map { "\($0.code) \(Fmt.points($0.points))" }.joined(separator: " · ")
        Text("🏆 \(top)")
    }
}

/// Before the first race of a season there are no tables yet.
struct NoStandingsView: View {
    let context: WidgetRenderContext

    var body: some View {
        switch context.size {
        case .inline, .circular, .rectangular:
            NextRaceWidgetView(context: context)
        default:
            WidgetMessage(symbol: "list.number", title: "No standings yet", message: "Standings appear after the first race of the season.")
                .widgetPadding(context.size)
        }
    }
}
