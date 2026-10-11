import SwiftUI
import WidgetKit

struct TeamWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        if let standing = context.team {
            switch context.size {
            case .small: TeamSmall(context: context, standing: standing)
            case .medium: TeamMedium(context: context, standing: standing)
            case .large: TeamLarge(context: context, standing: standing)
            case .extraLarge: TeamExtraLarge(context: context, standing: standing)
            case .circular: TeamCircular(context: context, standing: standing)
            case .rectangular: TeamRectangular(context: context, standing: standing)
            case .inline: TeamInline(standing: standing)
            }
        } else {
            NoStandingsView(context: context)
        }
    }
}

extension WidgetRenderContext {
    func teamGapText(for standing: ConstructorStanding) -> String {
        let table = snapshot.constructorStandings
        if standing.position == 1, table.count > 1 {
            return "+\(Fmt.points(standing.points - table[1].points)) lead"
        }
        return "\(Fmt.gap(standing.points - snapshot.constructorLeaderPoints)) to P1"
    }

    /// The team's drivers with the points they scored for it.
    func lineup(for standing: ConstructorStanding) -> [(driver: Driver, points: Double)] {
        let teamStats = self.stats.team(standing.constructor.id)
        let drivers = snapshot.drivers(of: standing.constructor.id)
        let pairs = drivers.map { ($0.driver, teamStats.driverPoints[$0.driver.id] ?? $0.points) }
        return Array(pairs.sorted { $0.1 > $1.1 }.prefix(2)).map { (driver: $0.0, points: $0.1) }
    }
}

private struct TeamCard: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding
    var nameSize: CGFloat = 18
    @Environment(\.palette) private var palette

    var body: some View {
        let lineup = context.lineup(for: standing)
        let color = context.teamColor(standing.constructor.id)
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 5) {
                if context.showFlags { FlagText(flag: Flags.nationality(standing.constructor.nationality), size: 12) }
                CapsLabel("Team", size: 8, color: palette.secondary)
                Spacer(minLength: 2)
                Text("P\(standing.position)")
                    .font(Typo.display(15, weight: .black))
                    .foregroundStyle(palette.primary)
                    .widgetAccentable()
            }
            Spacer(minLength: 0)
            Text(TeamPalette.shortName(for: standing.constructor).uppercased())
                .font(Typo.display(nameSize, weight: .heavy))
                .foregroundStyle(palette.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Fmt.points(standing.points))
                    .font(Typo.display(14, weight: .heavy).monospacedDigit())
                    .foregroundStyle(palette.primary)
                Text("PTS").font(Typo.label(7, weight: .heavy)).foregroundStyle(palette.secondary)
                Spacer(minLength: 4)
                Text(context.teamGapText(for: standing))
                    .font(Typo.number(9, weight: .semibold))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.top, 2)
            SplitBar(
                segments: lineup.map { (value: $0.points, color: color) },
                total: max(standing.points, lineup.reduce(0) { $0 + $1.points }),
                height: 5
            )
            .padding(.top, 7)
            HStack {
                ForEach(Array(lineup.enumerated()), id: \.offset) { index, entry in
                    if index > 0 { Spacer(minLength: 4) }
                    HStack(spacing: 3) {
                        Text(entry.driver.code)
                            .font(Typo.code(11, weight: .heavy))
                            .foregroundStyle(palette.primary)
                        Text(Fmt.points(entry.points))
                            .font(Typo.number(10, weight: .semibold))
                            .foregroundStyle(palette.secondary)
                    }
                }
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Small

private struct TeamSmall: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding

    var body: some View {
        TeamCard(context: context, standing: standing)
            .widgetPadding(.small)
    }
}

// MARK: - Medium

private struct TeamMedium: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding
    @Environment(\.palette) private var palette

    var body: some View {
        let stats = context.stats.team(standing.constructor.id)
        let lineup = context.lineup(for: standing)
        HStack(spacing: 16) {
            TeamCard(context: context, standing: standing, nameSize: 17)
                .frame(width: 140)
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    StatTile(value: "\(stats.wins)", label: "Wins")
                    StatTile(value: "\(stats.podiums)", label: "Podiums")
                    StatTile(value: "\(stats.oneTwos)", label: "1–2s")
                }
                Spacer(minLength: 6)
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(Array(lineup.enumerated()), id: \.offset) { _, entry in
                        HStack(spacing: 6) {
                            Text(entry.driver.code)
                                .font(Typo.code(11, weight: .heavy))
                                .foregroundStyle(palette.primary)
                                .frame(width: 30, alignment: .leading)
                            RecentForm(badges: context.stats.driver(entry.driver.id).recent(5), chipWidth: 22, chipHeight: 17)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .widgetPadding(.medium)
    }
}

// MARK: - Large

private struct TeamLarge: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding
    @Environment(\.palette) private var palette

    private var rivals: [ConstructorStanding] {
        let table = context.snapshot.constructorStandings
        guard let index = table.firstIndex(where: { $0.id == standing.id }) else { return [standing] }
        let neighbours = [index - 1, index + 1].filter { table.indices.contains($0) }.map { table[$0] }
        return [standing] + neighbours
    }

    var body: some View {
        let stats = context.stats.team(standing.constructor.id)
        let lineup = context.lineup(for: standing)
        let series = context.teamSeries(rivals, emphasize: standing.constructor.id).map { line -> ProgressSeries in
            var copy = line
            if line.id != standing.constructor.id {
                copy.dashed = true
                if palette.isLivery { copy.color = palette.secondary }
            }
            return copy
        }
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 10) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(palette.isLivery ? palette.primary : context.teamColor(standing.constructor.id))
                    .frame(width: 6, height: 40)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    CapsLabel("Constructors' Championship", size: 7.5, color: palette.tertiary)
                    Text(TeamPalette.shortName(for: standing.constructor).uppercased())
                        .font(Typo.display(21, weight: .heavy))
                        .foregroundStyle(palette.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
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
                StatTile(value: "\(stats.oneTwos)", label: "1–2s", valueSize: 17)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.top, 10)

            HStack {
                PointsLegend(series: series, size: 9.5)
                Spacer(minLength: 0)
                CapsLabel(context.teamGapText(for: standing), size: 7.5, color: palette.tertiary)
            }
            .padding(.top, 10)
            PointsChart(series: series)
                .frame(maxHeight: .infinity)
                .padding(.top, 4)

            VStack(spacing: 6) {
                ForEach(Array(lineup.enumerated()), id: \.offset) { _, entry in
                    HStack(spacing: 8) {
                        Text(entry.driver.familyName.uppercased())
                            .font(Typo.display(10.5, weight: .heavy))
                            .foregroundStyle(palette.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: 92, alignment: .leading)
                        Text("\(Fmt.points(entry.points))")
                            .font(Typo.number(11, weight: .bold))
                            .foregroundStyle(palette.secondary)
                            .frame(width: 30, alignment: .trailing)
                        Spacer(minLength: 4)
                        RecentForm(badges: context.stats.driver(entry.driver.id).recent(5), chipWidth: 24, chipHeight: 18)
                    }
                }
            }
            .padding(.top, 8)
        }
        .widgetPadding(context.size)
    }
}

// MARK: - Extra large (iPad)

private struct TeamExtraLarge: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding
    @Environment(\.palette) private var palette

    var body: some View {
        let stats = context.stats.team(standing.constructor.id)
        let lineup = context.lineup(for: standing)
        let table = context.snapshot.constructorStandings
        let index = table.firstIndex { $0.id == standing.id } ?? 0
        let rivals = [standing] + [index - 1, index + 1].filter { table.indices.contains($0) }.map { table[$0] }
        let series = context.teamSeries(rivals, emphasize: standing.constructor.id).map { line -> ProgressSeries in
            var copy = line
            if line.id != standing.constructor.id {
                copy.dashed = true
                if palette.isLivery { copy.color = palette.secondary }
            }
            return copy
        }
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 0) {
                TeamCard(context: context, standing: standing, nameSize: 20)
                    .frame(height: 140)
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 12) {
                    GridRow {
                        StatTile(value: "\(stats.wins)", label: "Wins", valueSize: 18)
                        StatTile(value: "\(stats.podiums)", label: "Podiums", valueSize: 18)
                    }
                    GridRow {
                        StatTile(value: "\(stats.poles)", label: "Poles", valueSize: 18)
                        StatTile(value: "\(stats.oneTwos)", label: "1–2s", valueSize: 18)
                    }
                }
                .padding(12)
                .background(palette.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 12)
                Spacer(minLength: 0)
            }
            .frame(width: 270)

            VStack(alignment: .leading, spacing: 8) {
                PointsLegend(series: series, size: 10)
                PointsChart(series: series)
                ForEach(Array(lineup.enumerated()), id: \.offset) { _, entry in
                    HStack(spacing: 8) {
                        Text(entry.driver.familyName.uppercased())
                            .font(Typo.display(10.5, weight: .heavy))
                            .foregroundStyle(palette.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .frame(width: 110, alignment: .leading)
                        Text(Fmt.points(entry.points))
                            .font(Typo.number(11, weight: .bold))
                            .foregroundStyle(palette.secondary)
                        Spacer(minLength: 4)
                        RecentForm(badges: context.stats.driver(entry.driver.id).recent(5), chipWidth: 26, chipHeight: 19)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .widgetPadding(.extraLarge)
    }
}

// MARK: - Lock Screen

private struct TeamCircular: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding

    var body: some View {
        let leader = max(context.snapshot.constructorLeaderPoints, 1)
        ZStack {
            AccessoryCircleBackground()
            RingGauge(fraction: standing.points / leader, lineWidth: 4.5)
                .padding(3)
            VStack(spacing: -2) {
                Text("P\(standing.position)").font(Typo.display(16, weight: .black))
                Text(TeamPalette.code(for: standing.constructor)).font(Typo.label(8, weight: .heavy)).opacity(0.8)
            }
        }
    }
}

private struct TeamRectangular: View {
    let context: WidgetRenderContext
    let standing: ConstructorStanding

    var body: some View {
        let lineup = context.lineup(for: standing)
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(TeamPalette.shortName(for: standing.constructor).uppercased())
                    .font(Typo.display(12.5, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                Text("P\(standing.position)").font(Typo.display(13, weight: .black))
            }
            .widgetAccentable()
            Text("\(Fmt.points(standing.points)) pts · \(context.teamGapText(for: standing))")
                .font(Typo.text(12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(lineup.map { "\($0.driver.code) \(Fmt.points($0.points))" }.joined(separator: " · "))
                .font(Typo.number(11.5, weight: .medium))
                .opacity(0.75)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TeamInline: View {
    let standing: ConstructorStanding

    var body: some View {
        Text("\(TeamPalette.code(for: standing.constructor)) P\(standing.position) · \(Fmt.points(standing.points)) pts")
    }
}
