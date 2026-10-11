import Charts
import SwiftUI
import WidgetKit

struct ProgressSeries: Identifiable {
    var id: String
    var label: String
    var color: Color
    var points: [ProgressPoint]
    var emphasized = false
    var dashed = false

    var total: Double { points.last?.points ?? 0 }
}

/// Cumulative points per round. The emphasised series gets a soft area fill.
struct PointsChart: View {
    let series: [ProgressSeries]
    var showsAxis = true
    var lineWidth: CGFloat = 2
    @Environment(\.palette) private var palette

    private var maxRound: Int { series.flatMap(\.points).map(\.round).max() ?? 1 }
    private var minRound: Int { series.flatMap(\.points).map(\.round).min() ?? 0 }
    private var maxPoints: Double { max(series.flatMap(\.points).map(\.points).max() ?? 1, 1) }

    var body: some View {
        if showsAxis {
            chart
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 3]))
                            .foregroundStyle(palette.hairline)
                        AxisValueLabel()
                            .font(Typo.number(8, weight: .medium))
                            .foregroundStyle(palette.tertiary)
                    }
                }
        } else {
            chart
                .chartYAxis(.hidden)
        }
    }

    private var chart: some View {
        Chart {
            ForEach(series.filter(\.emphasized)) { line in
                ForEach(line.points) { point in
                    AreaMark(
                        x: .value("Round", point.round),
                        yStart: .value("Base", 0),
                        yEnd: .value("Points", point.points)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [line.color.opacity(0.32), line.color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
            }
            ForEach(series) { line in
                ForEach(line.points) { point in
                    LineMark(
                        x: .value("Round", point.round),
                        y: .value("Points", point.points),
                        series: .value("Series", line.id)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(line.color)
                    .lineStyle(StrokeStyle(
                        lineWidth: line.emphasized ? lineWidth + 0.6 : lineWidth,
                        lineCap: .round,
                        lineJoin: .round,
                        dash: line.dashed ? [3, 3] : []
                    ))
                }
                if let last = line.points.last {
                    PointMark(x: .value("Round", last.round), y: .value("Points", last.points))
                        .foregroundStyle(line.color)
                        .symbolSize(line.emphasized ? 28 : 16)
                }
            }
        }
        .chartLegend(.hidden)
        .chartXScale(domain: minRound...max(maxRound, minRound + 1))
        .chartYScale(domain: 0...(maxPoints * 1.05))
        .chartXAxis(.hidden)
        .widgetAccentable()
    }
}

/// "● NOR 312   ● PIA 298" legend that replaces end-of-line labels.
struct PointsLegend: View {
    let series: [ProgressSeries]
    var size: CGFloat = 10
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            ForEach(series) { line in
                HStack(spacing: 4) {
                    Capsule(style: .continuous)
                        .fill(line.color)
                        .frame(width: 10, height: 3)
                        .opacity(line.dashed ? 0.6 : 1)
                    Text(line.label)
                        .font(Typo.code(size, weight: .heavy))
                        .foregroundStyle(palette.primary)
                    Text(Fmt.points(line.total))
                        .font(Typo.number(size - 1, weight: .semibold))
                        .foregroundStyle(palette.secondary)
                }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
    }
}

extension WidgetRenderContext {
    /// Progress lines for drivers, dashing the second driver of a team so teammates stay distinguishable.
    func driverSeries(_ standings: [DriverStanding], emphasize: String? = nil) -> [ProgressSeries] {
        var seenTeams: Set<String> = []
        return standings.map { standing in
            let teamId = standing.constructor?.id ?? ""
            let dashed = seenTeams.contains(teamId)
            seenTeams.insert(teamId)
            return ProgressSeries(
                id: standing.driver.id,
                label: standing.driver.code,
                color: teamColor(teamId),
                points: stats.progress(driver: standing.driver.id),
                emphasized: standing.driver.id == emphasize,
                dashed: dashed
            )
        }
    }

    func teamSeries(_ standings: [ConstructorStanding], emphasize: String? = nil) -> [ProgressSeries] {
        standings.map { standing in
            ProgressSeries(
                id: standing.constructor.id,
                label: TeamPalette.code(for: standing.constructor),
                color: teamColor(standing.constructor.id),
                points: stats.progress(team: standing.constructor.id),
                emphasized: standing.constructor.id == emphasize
            )
        }
    }
}
