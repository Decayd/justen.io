import SwiftUI

struct DriverDetailView: View {
    let driverId: String
    var season: Int?

    var body: some View {
        ScrollView {
            SeasonContent(season: season) { snapshot, stats in
                DriverDetailContent(snapshot: snapshot, stats: stats, driverId: driverId)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct DriverDetailContent: View {
    let snapshot: SeasonSnapshot
    let stats: SeasonStats
    let driverId: String
    @Environment(\.palette) private var palette

    var body: some View {
        if let standing = snapshot.driverStanding(id: driverId) {
            let driverStats = stats.driver(driverId)
            let teamRGB = TeamPalette.rgb(for: standing.constructor?.id, season: snapshot.standingsSeason)
            VStack(spacing: 16) {
                DriverHeader(standing: standing, teamRGB: teamRGB, season: snapshot.standingsSeason)
                statsGrid(standing: standing, stats: driverStats)
                progression(standing: standing)
                if let h2h = stats.headToHead(driver: driverId) {
                    HeadToHeadCard(record: h2h, driver: standing.driver, color: palette.team(teamRGB))
                }
                resultsCard(stats: driverStats)
            }
            .navigationTitle(standing.driver.familyName)
        } else {
            ContentUnavailableView("No results for this driver", systemImage: "person.fill.questionmark")
        }
    }

    private func statsGrid(standing: DriverStanding, stats: DriverSeasonStats) -> some View {
        Card {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 16) {
                GridRow {
                    StatBlock(value: "P\(standing.position)", label: "Position")
                    StatBlock(value: Fmt.points(standing.points), label: "Points")
                    StatBlock(value: "\(stats.wins)", label: "Wins")
                    StatBlock(value: "\(stats.podiums)", label: "Podiums")
                }
                GridRow {
                    StatBlock(value: "\(stats.poles)", label: "Poles")
                    StatBlock(value: "\(stats.fastestLaps)", label: "Fastest laps")
                    StatBlock(value: "\(stats.retirements)", label: "DNFs")
                    StatBlock(value: stats.averageFinish.map { String(format: "%.1f", $0) } ?? "–", label: "Avg finish")
                }
            }
        }
    }

    @ViewBuilder
    private func progression(standing: DriverStanding) -> some View {
        let rivalId = standing.position == 1 ? snapshot.driverStandings.dropFirst().first?.driver.id : snapshot.driverStandings.first?.driver.id
        let rival = rivalId.flatMap { snapshot.driverStanding(id: $0) }
        let series: [ProgressSeries] = [
            ProgressSeries(
                id: standing.driver.id,
                label: standing.driver.code,
                color: palette.team(standing.constructor?.id, season: snapshot.standingsSeason),
                points: stats.progress(driver: standing.driver.id),
                emphasized: true
            ),
        ] + (rival.map {
            [ProgressSeries(id: $0.driver.id, label: $0.driver.code, color: .secondary, points: stats.progress(driver: $0.driver.id), dashed: true)]
        } ?? [])
        if stats.rounds.count > 1 {
            Card {
                SectionTitle("Points progression")
                PointsLegend(series: series, size: 11)
                    .padding(.top, 10)
                PointsChart(series: series, lineWidth: 2.4)
                    .frame(height: 190)
                    .padding(.top, 8)
            }
        }
    }

    private func roundDetail(_ badge: ResultBadge) -> String {
        let quali = snapshot.results(round: badge.round)?.qualifying.first(where: { $0.driver.id == driverId })?.position
        guard let quali else { return "Round \(badge.round)" }
        return "Round \(badge.round) · Qualified P\(quali)"
    }

    private func resultsCard(stats: DriverSeasonStats) -> some View {
        Card {
            SectionTitle("Race by race")
            VStack(spacing: 0) {
                ForEach(stats.results.reversed()) { badge in
                    let detail = roundDetail(badge)
                    HStack(spacing: 10) {
                        Text(Flags.country(badge.country)).font(.title3)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(badge.raceName).font(.subheadline.weight(.semibold))
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if badge.points > 0 {
                            Text("+\(Fmt.points(badge.points))")
                                .font(Typo.number(13, weight: .bold))
                                .foregroundStyle(.secondary)
                        }
                        ResultChip(badge: badge, width: 38, height: 26)
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct DriverHeader: View {
    let standing: DriverStanding
    let teamRGB: RGB
    let season: Int

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [teamRGB.lighter(0.05).color, teamRGB.darker(0.45).color], startPoint: .topLeading, endPoint: .bottomTrailing)
            if let number = standing.driver.number {
                Text(number)
                    .font(.system(size: 150, weight: .black).width(.expanded).italic())
                    .foregroundStyle(teamRGB.onColor.color.opacity(0.14))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .offset(x: 10, y: -10)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(Flags.nationality(standing.driver.nationality))
                    Text((standing.constructor.map(TeamPalette.shortName) ?? "").uppercased())
                        .font(Typo.label(11, weight: .heavy))
                }
                .foregroundStyle(teamRGB.onColor.color.opacity(0.8))
                Text(standing.driver.givenName)
                    .font(.title3.weight(.medium))
                Text(standing.driver.familyName.uppercased())
                    .font(Typo.display(30, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                HStack(spacing: 14) {
                    Label("P\(standing.position) in \(String(season))", systemImage: "list.number")
                    Label("\(Fmt.points(standing.points)) pts", systemImage: "sum")
                }
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)
            }
            .foregroundStyle(teamRGB.onColor.color)
            .padding(20)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

private struct HeadToHeadCard: View {
    let record: HeadToHead
    let driver: Driver
    let color: Color

    var body: some View {
        Card {
            SectionTitle("Teammate battle")
            HStack {
                Text(driver.code).font(Typo.code(17))
                Spacer()
                Text("vs").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(record.teammate.code).font(Typo.code(17)).foregroundStyle(.secondary)
            }
            .padding(.top, 10)
            battle(title: "Races", ahead: record.raceAhead, behind: record.raceBehind)
                .padding(.top, 10)
            battle(title: "Qualifying", ahead: record.qualifyingAhead, behind: record.qualifyingBehind)
                .padding(.top, 10)
        }
    }

    private func battle(title: String, ahead: Int, behind: Int) -> some View {
        let total = max(ahead + behind, 1)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(ahead)").font(Typo.number(15, weight: .heavy))
                Spacer()
                Text(title.uppercased()).font(Typo.label(9, weight: .bold)).foregroundStyle(.secondary)
                Spacer()
                Text("\(behind)").font(Typo.number(15, weight: .heavy)).foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                HStack(spacing: 3) {
                    Capsule().fill(color).frame(width: max(4, proxy.size.width * CGFloat(ahead) / CGFloat(total) - 1.5))
                    Capsule().fill(Color.secondary.opacity(0.35))
                }
            }
            .frame(height: 8)
        }
    }
}
