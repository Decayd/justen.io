import SwiftUI
import WidgetKit

struct TitleFightWidgetView: View {
    let context: WidgetRenderContext

    var body: some View {
        let table = context.snapshot.driverStandings
        if table.count >= 2 {
            switch context.size {
            case .small: TitleFightSmall(context: context, table: table)
            case .medium: TitleFightMedium(context: context, table: table)
            case .large, .extraLarge: TitleFightLarge(context: context, table: table)
            case .circular: TitleFightCircular(table: table)
            case .rectangular: TitleFightRectangular(context: context, table: table)
            case .inline: TitleFightInline(table: table)
            }
        } else {
            NoStandingsView(context: context)
        }
    }
}

extension WidgetRenderContext {
    /// "5 races left · 145 pts available" or "Champion decided".
    var titleFightCaption: String {
        let remaining = snapshot.remainingRaces.count
        if remaining == 0 { return "Final standings" }
        return "\(remaining) \(remaining == 1 ? "race" : "races") · \(Fmt.points(snapshot.maxPointsRemaining)) pts left"
    }

    /// Up to `limit` drivers who can still win, at least two.
    func contenders(limit: Int) -> [DriverStanding] {
        let alive = snapshot.contenders
        let base = alive.count >= 2 ? alive : Array(snapshot.driverStandings.prefix(2))
        return Array(base.prefix(limit))
    }
}

// MARK: - Small

private struct TitleFightSmall: View {
    let context: WidgetRenderContext
    let table: [DriverStanding]
    @Environment(\.palette) private var palette

    var body: some View {
        let leader = table[0]
        let chaser = table[1]
        let gap = leader.points - chaser.points
        VStack(alignment: .leading, spacing: 0) {
            CapsLabel("Title fight", size: 9)
            Spacer(minLength: 4)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(Fmt.points(gap))
                    .font(Typo.display(38, weight: .black).monospacedDigit())
                    .foregroundStyle(palette.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("PTS")
                    .font(Typo.label(9, weight: .heavy))
                    .foregroundStyle(palette.secondary)
            }
            Text("\(leader.driver.code) leads \(chaser.driver.code)")
                .font(Typo.text(11, weight: .semibold))
                .foregroundStyle(palette.secondary)
                .lineLimit(1)
            Spacer(minLength: 6)
            DuelBar(context: context, leader: leader, chaser: chaser)
            Text(context.titleFightCaption)
                .font(Typo.text(9, weight: .medium))
                .foregroundStyle(palette.tertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 5)
        }
        .widgetPadding(.small)
    }
}

/// Two bars facing off, scaled to the leader.
private struct DuelBar: View {
    let context: WidgetRenderContext
    let leader: DriverStanding
    let chaser: DriverStanding
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 4) {
            row(leader, fraction: 1)
            row(chaser, fraction: leader.points > 0 ? chaser.points / leader.points : 0)
        }
    }

    private func row(_ standing: DriverStanding, fraction: Double) -> some View {
        HStack(spacing: 6) {
            Text(standing.driver.code)
                .font(Typo.code(10.5, weight: .heavy))
                .foregroundStyle(palette.primary)
                .frame(width: 28, alignment: .leading)
            PointsBar(fraction: fraction, color: context.teamColor(standing.constructor?.id), height: 5)
        }
    }
}

// MARK: - Medium

private struct TitleFightMedium: View {
    let context: WidgetRenderContext
    let table: [DriverStanding]
    @Environment(\.palette) private var palette

    var body: some View {
        let contenders = context.contenders(limit: 3)
        let series = context.driverSeries(contenders, emphasize: contenders.first?.driver.id)
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    CapsLabel("Title fight", size: 9)
                    Spacer(minLength: 0)
                }
                PointsChart(series: series, showsAxis: false)
            }
            .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(contenders.enumerated()), id: \.offset) { index, standing in
                    ContenderRow(context: context, standing: standing, leaderPoints: contenders[0].points, isDashed: series[index].dashed)
                        .frame(maxHeight: .infinity)
                }
                Text(context.titleFightCaption)
                    .font(Typo.text(9, weight: .medium))
                    .foregroundStyle(palette.tertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 118)
        }
        .widgetPadding(.medium)
    }
}

private struct ContenderRow: View {
    let context: WidgetRenderContext
    let standing: DriverStanding
    let leaderPoints: Double
    var isDashed = false
    var showMax = false
    @Environment(\.palette) private var palette

    var body: some View {
        let color = context.teamColor(standing.constructor?.id)
        HStack(spacing: 6) {
            Capsule(style: .continuous)
                .fill(color)
                .frame(width: 10, height: 3)
                .opacity(isDashed ? 0.6 : 1)
                .widgetAccentable()
            Text(standing.driver.code)
                .font(Typo.code(13, weight: .heavy))
                .foregroundStyle(palette.primary)
            Spacer(minLength: 2)
            VStack(alignment: .trailing, spacing: 0) {
                Text(Fmt.points(standing.points))
                    .font(Typo.number(12, weight: .heavy))
                    .foregroundStyle(palette.primary)
                Text(standing.points == leaderPoints ? "LEADER" : Fmt.gap(standing.points - leaderPoints))
                    .font(Typo.number(8.5, weight: .bold))
                    .foregroundStyle(standing.points == leaderPoints ? palette.accent : palette.secondary)
            }
            if showMax {
                Text(Fmt.points(standing.points + context.snapshot.maxPointsRemaining))
                    .font(Typo.number(11, weight: .semibold))
                    .foregroundStyle(palette.tertiary)
                    .frame(width: 40, alignment: .trailing)
            }
        }
    }
}

// MARK: - Large

private struct TitleFightLarge: View {
    let context: WidgetRenderContext
    let table: [DriverStanding]
    @Environment(\.palette) private var palette

    var body: some View {
        let contenders = context.contenders(limit: 4)
        let series = context.driverSeries(contenders, emphasize: contenders.first?.driver.id)
        let alive = context.snapshot.contenders.count
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                CapsLabel("Drivers' title fight", size: 9)
                Spacer(minLength: 0)
                CapsLabel("R\(context.snapshot.standingsRound)/\(context.snapshot.totalRounds)", size: 8.5, color: palette.tertiary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(contenders[0].driver.familyName.uppercased())")
                    .font(Typo.display(19, weight: .heavy))
                    .foregroundStyle(palette.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                if contenders.count > 1 {
                    Text("leads by \(Fmt.points(contenders[0].points - contenders[1].points))")
                        .font(Typo.text(12, weight: .semibold))
                        .foregroundStyle(palette.secondary)
                }
            }
            .padding(.top, 6)

            PointsChart(series: series)
                .frame(maxHeight: .infinity)
                .padding(.top, 10)

            Rectangle().fill(palette.hairline).frame(height: 1).padding(.vertical, 8)

            HStack {
                CapsLabel("Driver", size: 7.5, color: palette.tertiary)
                Spacer()
                CapsLabel("Max possible", size: 7.5, color: palette.tertiary)
            }
            .padding(.bottom, 4)
            VStack(spacing: 6) {
                ForEach(Array(contenders.enumerated()), id: \.offset) { index, standing in
                    ContenderRow(
                        context: context,
                        standing: standing,
                        leaderPoints: contenders[0].points,
                        isDashed: series[index].dashed,
                        showMax: true
                    )
                }
            }
            HStack(spacing: 5) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(palette.accent)
                    .widgetAccentable()
                Text(alive <= 1 ? "Champion decided" : "\(alive) drivers can still win · \(context.titleFightCaption)")
                    .font(Typo.text(10, weight: .medium))
                    .foregroundStyle(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.top, 8)
        }
        .widgetPadding(context.size)
    }
}

// MARK: - Lock Screen

private struct TitleFightCircular: View {
    let table: [DriverStanding]

    var body: some View {
        let gap = table[0].points - table[1].points
        ZStack {
            AccessoryCircleBackground()
            RingGauge(fraction: table[0].points > 0 ? table[1].points / table[0].points : 0, lineWidth: 4.5)
                .padding(3)
            VStack(spacing: -2) {
                Text(Fmt.points(gap)).font(Typo.display(16, weight: .black)).minimumScaleFactor(0.6)
                Text(table[0].driver.code).font(Typo.label(8, weight: .heavy)).opacity(0.8)
            }
        }
    }
}

private struct TitleFightRectangular: View {
    let context: WidgetRenderContext
    let table: [DriverStanding]

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("TITLE FIGHT")
                .font(Typo.label(10, weight: .heavy))
                .widgetAccentable()
            Text("\(table[0].driver.code) \(Fmt.points(table[0].points)) · \(table[1].driver.code) \(Fmt.points(table[1].points))")
                .font(Typo.display(12, weight: .heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(context.titleFightCaption)
                .font(Typo.text(11.5, weight: .medium))
                .opacity(0.75)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TitleFightInline: View {
    let table: [DriverStanding]

    var body: some View {
        Text("\(table[0].driver.code) leads \(table[1].driver.code) by \(Fmt.points(table[0].points - table[1].points))")
    }
}
