import SwiftUI
import WidgetKit

struct DriverWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        if let standing = context.driver {
            switch context.size {
            case .small: DriverSmall(context: context, standing: standing)
            case .medium: DriverMedium(context: context, standing: standing)
            case .large, .extraLarge: DriverLarge(context: context, standing: standing)
            case .circular: DriverCircular(context: context, standing: standing)
            case .rectangular: DriverRectangular(context: context, standing: standing)
            case .inline: DriverInline(context: context, standing: standing)
            }
        } else {
            NoStandingsView(context: context)
        }
    }
}

extension WidgetRenderContext {
    /// Gap to the leader, or the lead over P2 for the leader.
    func gapText(for standing: DriverStanding) -> String {
        let table = snapshot.driverStandings
        if standing.position == 1, table.count > 1 {
            return "+\(Fmt.points(standing.points - table[1].points)) lead"
        }
        return "\(Fmt.gap(standing.points - snapshot.leaderPoints)) to P1"
    }
}

/// Big translucent race number used as a graphic element.
private struct DriverNumber: View {
    let number: String
    let size: CGFloat
    let color: Color

    var body: some View {
        Text(number)
            .font(.system(size: size, weight: .black).width(.expanded).italic())
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .fixedSize()
    }
}

/// Name, team and championship position.
private struct DriverIdentity: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    var nameSize: CGFloat = 17
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(standing.driver.givenName)
                .font(Typo.text(nameSize * 0.62, weight: .semibold))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
            Text(standing.driver.familyName.uppercased())
                .font(Typo.display(nameSize, weight: .heavy))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
    }
}

private struct PointsLine: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    var size: CGFloat = 15
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(Fmt.points(standing.points))
                .font(Typo.display(size, weight: .heavy).monospacedDigit())
                .foregroundStyle(palette.primary)
            Text("PTS")
                .font(Typo.label(size * 0.5, weight: .heavy))
                .foregroundStyle(palette.secondary)
            Spacer(minLength: 4)
            Text(context.gapText(for: standing))
                .font(Typo.number(size * 0.62, weight: .semibold))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}

// MARK: - Small

private struct DriverSmall: View {
    let context: WidgetRenderContext
    let standing: DriverStanding

    var body: some View {
        DriverCard(context: context, standing: standing)
            .widgetPadding(.small)
            .background(alignment: .topTrailing) {
                DriverNumberWatermark(context: context, standing: standing)
            }
    }
}

private struct DriverNumberWatermark: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    var size: CGFloat = 84
    @Environment(\.palette) private var palette

    var body: some View {
        if let number = standing.driver.number {
            DriverNumber(
                number: number,
                size: size,
                color: palette.isLivery ? palette.primary.opacity(0.14) : context.teamColor(standing.constructor?.id).opacity(0.22)
            )
            .offset(x: size * 0.07, y: size * 0.26)
        }
    }
}

/// Flag, team, position, name and points: the core of the small and medium layouts.
private struct DriverCard: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                if context.showFlags { FlagText(flag: Flags.nationality(standing.driver.nationality), size: 12) }
                CapsLabel(standing.constructor.map(TeamPalette.shortName) ?? "", size: 8, color: palette.secondary)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 2)
                Text("P\(standing.position)")
                    .font(Typo.display(15, weight: .black))
                    .foregroundStyle(palette.primary)
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                if !palette.isLivery {
                    TeamStripe(color: context.teamColor(standing.constructor?.id), width: 3.5, height: 34)
                }
                DriverIdentity(context: context, standing: standing, nameSize: 16)
            }
            PointsLine(context: context, standing: standing, size: 14)
                .padding(.top, 6)
        }
    }
}

// MARK: - Medium

private struct DriverMedium: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    @Environment(\.palette) private var palette

    private var stats: DriverSeasonStats { context.stats.driver(standing.driver.id) }

    var body: some View {
        HStack(spacing: 16) {
            DriverCard(context: context, standing: standing)
                .frame(width: 136)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    StatTile(value: "\(stats.wins)", label: "Wins")
                    StatTile(value: "\(stats.podiums)", label: "Podiums")
                    StatTile(value: "\(stats.poles)", label: "Poles")
                }
                Spacer(minLength: 6)
                CapsLabel("Last \(min(5, stats.results.count)) races", size: 7.5, color: palette.tertiary)
                    .padding(.bottom, 4)
                RecentForm(badges: stats.recent(5), chipWidth: 27, chipHeight: 22)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetPadding(.medium)
        .background(alignment: .topLeading) {
            DriverNumberWatermark(context: context, standing: standing, size: 84)
                .offset(x: 70)
        }
    }
}

/// The last few results as chips, oldest first.
struct RecentForm: View {
    let badges: [ResultBadge]
    var chipWidth: CGFloat = 26
    var chipHeight: CGFloat = 18
    var showFlags = false

    var body: some View {
        HStack(spacing: 4) {
            if badges.isEmpty {
                ResultChip(badge: ResultBadge.placeholder, width: chipWidth, height: chipHeight).opacity(0.4)
            }
            ForEach(badges) { badge in
                VStack(spacing: 2) {
                    ResultChip(badge: badge, width: chipWidth, height: chipHeight)
                    if showFlags {
                        Text(Flags.country(badge.country)).font(.system(size: 9))
                    }
                }
            }
        }
    }
}

extension ResultBadge {
    static var placeholder: ResultBadge {
        ResultBadge(
            result: RaceResult(
                position: nil, positionText: "-", points: 0,
                driver: Driver(id: "-", code: "-", givenName: "", familyName: "", nationality: ""),
                constructor: nil, grid: nil, laps: nil, status: "", time: nil, fastestLapRank: nil, fastestLapTime: nil
            ),
            round: 0,
            race: nil
        )
    }
}

// MARK: - Large

private struct DriverLarge: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    @Environment(\.palette) private var palette

    private var stats: DriverSeasonStats { context.stats.driver(standing.driver.id) }
    private var teamColor: Color { context.teamColor(standing.constructor?.id) }

    /// The driver against the leader, or against P2 when leading.
    private var rivals: [DriverStanding] {
        let table = context.snapshot.driverStandings
        let rival = standing.position == 1 ? table.dropFirst().first : table.first
        return [standing] + (rival.map { [$0] } ?? [])
    }

    var body: some View {
        let series = context.driverSeries(rivals, emphasize: standing.driver.id).map { line -> ProgressSeries in
            var copy = line
            if line.id != standing.driver.id {
                copy.color = palette.secondary
                copy.dashed = true
            }
            return copy
        }

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                if let number = standing.driver.number {
                    DriverNumber(number: number, size: 40, color: palette.isLivery ? palette.primary : teamColor)
                        .widgetAccentable()
                }
                VStack(alignment: .leading, spacing: 1) {
                    DriverIdentity(context: context, standing: standing, nameSize: 19)
                    HStack(spacing: 4) {
                        if context.showFlags { Text(Flags.nationality(standing.driver.nationality)).font(.system(size: 10)) }
                        Text(standing.constructor.map(TeamPalette.shortName) ?? "")
                            .font(Typo.text(10.5, weight: .semibold))
                            .foregroundStyle(palette.secondary)
                    }
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 0) {
                    Text("P\(standing.position)")
                        .font(Typo.display(26, weight: .black))
                        .foregroundStyle(palette.primary)
                        .widgetAccentable()
                    Text("\(Fmt.points(standing.points)) PTS")
                        .font(Typo.number(11, weight: .bold))
                        .foregroundStyle(palette.secondary)
                }
            }

            HStack(spacing: 8) {
                StatTile(value: "\(stats.wins)", label: "Wins", valueSize: 17)
                StatTile(value: "\(stats.podiums)", label: "Podiums", valueSize: 17)
                StatTile(value: "\(stats.poles)", label: "Poles", valueSize: 17)
                StatTile(value: stats.averageFinish.map { String(format: "%.1f", $0) } ?? "–", label: "Avg finish", valueSize: 17)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.top, 10)

            HStack {
                PointsLegend(series: series, size: 9.5)
                Spacer(minLength: 0)
                CapsLabel(context.gapText(for: standing), size: 7.5, color: palette.tertiary)
            }
            .padding(.top, 10)
            PointsChart(series: series, lineWidth: 2)
                .frame(maxHeight: .infinity)
                .padding(.top, 4)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    CapsLabel("Recent form", size: 7.5, color: palette.tertiary)
                    RecentForm(badges: stats.recent(5), chipWidth: 28, chipHeight: 20, showFlags: context.showFlags)
                }
                Spacer(minLength: 6)
                NextRaceTag(context: context)
            }
            .padding(.top, 8)
        }
        .widgetPadding(context.size)
    }
}

/// "NEXT 🇸🇬 SINGAPORE · 3d 14h"
struct NextRaceTag: View {
    let context: WidgetRenderContext
    @Environment(\.palette) private var palette

    var body: some View {
        if let race = context.snapshot.nextRace(after: context.now) {
            VStack(alignment: .trailing, spacing: 2) {
                CapsLabel("Next", size: 7.5, color: palette.tertiary)
                HStack(spacing: 4) {
                    if context.showFlags { Text(context.flag(for: race)).font(.system(size: 11)) }
                    Text(race.shortName.uppercased())
                        .font(Typo.display(10, weight: .heavy))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Text(Countdown(now: context.now, session: race.raceSession).compact)
                    .font(Typo.number(10, weight: .bold))
                    .foregroundStyle(palette.accent)
            }
        }
    }
}

// MARK: - Lock Screen

private struct DriverCircular: View {
    let context: WidgetRenderContext
    let standing: DriverStanding

    var body: some View {
        let leader = max(context.snapshot.leaderPoints, 1)
        ZStack {
            AccessoryCircleBackground()
            RingGauge(fraction: standing.points / leader, lineWidth: 4.5)
                .padding(3)
            VStack(spacing: -2) {
                Text("P\(standing.position)").font(Typo.display(16, weight: .black))
                Text(standing.driver.code).font(Typo.label(8, weight: .heavy)).opacity(0.8)
            }
        }
    }
}

private struct DriverRectangular: View {
    let context: WidgetRenderContext
    let standing: DriverStanding

    var body: some View {
        let recent = context.stats.driver(standing.driver.id).recent(5)
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(standing.driver.familyName.uppercased())
                    .font(Typo.display(12.5, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                Text("P\(standing.position)")
                    .font(Typo.display(13, weight: .black))
            }
            .widgetAccentable()
            Text("\(Fmt.points(standing.points)) pts · \(context.gapText(for: standing))")
                .font(Typo.text(12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(recent.isEmpty ? "No races yet" : "Form " + recent.map { $0.position.map(String.init) ?? $0.label }.joined(separator: " "))
                .font(Typo.number(11.5, weight: .medium))
                .opacity(0.75)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DriverInline: View {
    let context: WidgetRenderContext
    let standing: DriverStanding

    var body: some View {
        Text("\(standing.driver.code) P\(standing.position) · \(Fmt.points(standing.points)) pts")
    }
}
