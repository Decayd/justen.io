import SwiftUI

struct TeamDetailView: View {
    let constructorId: String
    var season: Int?

    var body: some View {
        ScrollView {
            SeasonContent(season: season) { snapshot, stats in
                TeamDetailContent(snapshot: snapshot, stats: stats, constructorId: constructorId, archived: season != nil)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct TeamDetailContent: View {
    let snapshot: SeasonSnapshot
    let stats: SeasonStats
    let constructorId: String
    let archived: Bool
    @Environment(\.palette) private var palette

    var body: some View {
        if let standing = snapshot.constructorStanding(id: constructorId) {
            let teamStats = stats.team(constructorId)
            let teamRGB = TeamPalette.rgb(for: constructorId, season: snapshot.standingsSeason)
            let drivers = snapshot.drivers(of: constructorId)
            VStack(spacing: 16) {
                header(standing: standing, rgb: teamRGB)
                Card {
                    HStack {
                        StatBlock(value: "P\(standing.position)", label: "Position")
                        StatBlock(value: Fmt.points(standing.points), label: "Points")
                        StatBlock(value: "\(teamStats.wins)", label: "Wins")
                    }
                    HStack {
                        StatBlock(value: "\(teamStats.podiums)", label: "Podiums")
                        StatBlock(value: "\(teamStats.oneTwos)", label: "1–2 finishes")
                        StatBlock(value: "\(teamStats.poles)", label: "Poles")
                    }
                    .padding(.top, 16)
                }
                driversCard(standing: standing, drivers: drivers, teamStats: teamStats, rgb: teamRGB)
                progression(standing: standing)
            }
            .navigationTitle(TeamPalette.shortName(for: standing.constructor))
        } else {
            ContentUnavailableView("No results for this team", systemImage: "car.fill")
        }
    }

    private func header(standing: ConstructorStanding, rgb: RGB) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(Flags.nationality(standing.constructor.nationality))
                Text("CONSTRUCTORS' CHAMPIONSHIP")
                    .font(Typo.label(10, weight: .heavy))
            }
            .foregroundStyle(rgb.onColor.color.opacity(0.8))
            Text(standing.constructor.name.uppercased())
                .font(Typo.display(28, weight: .heavy))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            HStack(spacing: 14) {
                Label("P\(standing.position) in \(String(snapshot.standingsSeason))", systemImage: "list.number")
                Label("\(Fmt.points(standing.points)) pts", systemImage: "sum")
            }
            .font(.subheadline.weight(.semibold))
            .padding(.top, 4)
        }
        .foregroundStyle(rgb.onColor.color)
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 170, alignment: .bottomLeading)
        .background(
            LinearGradient(colors: [rgb.lighter(0.05).color, rgb.darker(0.45).color], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func driversCard(standing: ConstructorStanding, drivers: [DriverStanding], teamStats: TeamSeasonStats, rgb: RGB) -> some View {
        let color = palette.team(rgb)
        let contributions = drivers.map { ($0, teamStats.driverPoints[$0.driver.id] ?? $0.points) }
        return Card {
            SectionTitle("Drivers")
            SplitBar(
                segments: contributions.map { (value: $0.1, color: color) },
                total: max(standing.points, contributions.reduce(0) { $0 + $1.1 }),
                height: 10
            )
            .padding(.top, 12)
            VStack(spacing: 0) {
                ForEach(Array(contributions.enumerated()), id: \.offset) { index, item in
                    NavigationLink(value: Route.driver(item.0.driver.id, season: archived ? snapshot.standingsSeason : nil)) {
                        HStack(spacing: 10) {
                            Circle()
                                .fill(color.opacity(index == 0 ? 1 : 0.55))
                                .frame(width: 10, height: 10)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.0.driver.fullName).font(.body.weight(.semibold))
                                Text("P\(item.0.position) overall · \(stats.driver(item.0.driver.id).wins) wins")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            RecentForm(badges: stats.driver(item.0.driver.id).recent(5), chipWidth: 24, chipHeight: 20)
                            Text(Fmt.points(item.1))
                                .font(Typo.number(15, weight: .heavy))
                                .frame(minWidth: 36, alignment: .trailing)
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if index < contributions.count - 1 { Divider() }
                }
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func progression(standing: ConstructorStanding) -> some View {
        let table = snapshot.constructorStandings
        let index = table.firstIndex { $0.id == standing.id } ?? 0
        let rivals = [index - 1, index, index + 1].filter { table.indices.contains($0) }.map { table[$0] }
        let series = rivals.map { rival in
            ProgressSeries(
                id: rival.constructor.id,
                label: TeamPalette.code(for: rival.constructor),
                color: palette.team(rival.constructor.id, season: snapshot.standingsSeason),
                points: stats.progress(team: rival.constructor.id),
                emphasized: rival.id == standing.id,
                dashed: rival.id != standing.id
            )
        }
        if stats.rounds.count > 1 {
            Card {
                SectionTitle("Points progression")
                PointsLegend(series: series, size: 11)
                    .padding(.top, 10)
                PointsChart(series: series, lineWidth: 2.2)
                    .frame(height: 190)
                    .padding(.top, 8)
            }
        }
    }
}
