import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.homePath) {
            ScrollView {
                VStack(spacing: 18) {
                    SampleDataBanner()
                    if let snapshot = model.snapshot, let stats = model.stats {
                        content(snapshot: snapshot, stats: stats)
                    } else if !model.isShowingSampleData || model.isRefreshing {
                        LoadingState()
                    } else {
                        content(snapshot: model.previewSnapshot, stats: model.previewStats)
                    }
                    DataFooter()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Paddock")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .refreshable { await model.refresh(force: true) }
            .navigationDestination(for: Route.self) { RouteView(route: $0) }
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    @ViewBuilder
    private func content(snapshot: SeasonSnapshot, stats: SeasonStats) -> some View {
        if let race = snapshot.nextRace(after: Date()) {
            NavigationLink(value: Route.race(season: race.season, round: race.round)) {
                NextRaceHero(snapshot: snapshot, race: race)
            }
            .buttonStyle(.plain)
        }

        if let results = snapshot.latestRaceResults, let race = snapshot.standingsRace(round: results.round) {
            NavigationLink(value: Route.race(season: race.season, round: race.round)) {
                LastRaceCard(snapshot: snapshot, race: race, results: results)
            }
            .buttonStyle(.plain)
        }

        if !snapshot.driverStandings.isEmpty {
            ChampionshipCard(snapshot: snapshot, stats: stats)
            ConstructorsCard(snapshot: snapshot)
        }
    }
}

// MARK: - Next race hero

struct NextRaceHero: View {
    let snapshot: SeasonSnapshot
    let race: Race

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let now = timeline.date
            let target = snapshot.countdownTarget(for: race, now: now, mode: .smart)
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Text(Flags.country(race.circuit.country)).font(.title2)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("ROUND \(race.round) OF \(snapshot.races.count)")
                            .font(Typo.label(10, weight: .heavy))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(Fmt.weekend(race).uppercased())
                            .font(Typo.label(10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                    if race.isSprintWeekend { SprintBadge() }
                }

                Text(race.name.uppercased())
                    .font(Typo.display(26, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text("\(race.circuit.name) · \(race.circuit.locality)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))

                TrackMapView(circuit: race.circuit, color: AppColors.red, lineWidth: 3.5)
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    Text(target.state(at: now) == .live ? "\(target.kind.label.uppercased()) · ON TRACK" : "UNTIL \(target.kind.label.uppercased())")
                        .font(Typo.label(10, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.55))
                    if target.state(at: now) == .live {
                        LiveBadge(text: "LIVE NOW")
                    } else {
                        LiveCountdown(target: target.start)
                    }
                }

                Divider().overlay(.white.opacity(0.15))

                ScheduleList(race: race, now: now, highlight: target)
                    .frame(height: CGFloat(race.sessions.count) * 28)
            }
            .padding(18)
            .background(HeroBackground())
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .environment(\.palette, .dark(accent: RGB(hex: "#E10600"), background: .carbon))
            .environment(\.colorScheme, .dark)
        }
    }
}

// MARK: - Last race

struct LastRaceCard: View {
    let snapshot: SeasonSnapshot
    let race: Race
    let results: RoundResults
    @Environment(\.palette) private var palette

    var body: some View {
        Card {
            SectionTitle(title: "Latest result") {
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            HStack(spacing: 8) {
                Text(Flags.country(race.circuit.country)).font(.title3)
                Text(race.name)
                    .font(.headline)
                Spacer()
                Text(Fmt.day(race.start))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 10)

            PodiumView(
                entries: results.podium.map {
                    PodiumEntry(
                        position: Int($0.positionText) ?? 0,
                        code: $0.driver.code,
                        team: TeamPalette.rgb(for: $0.constructor?.id, season: race.season),
                        detail: $0.time
                    )
                },
                codeSize: 15,
                showDetail: true
            )
            .frame(height: 150)
            .padding(.horizontal, 24)
            .padding(.top, 14)

            if let fastest = results.fastestLap {
                HStack(spacing: 8) {
                    Image(systemName: "stopwatch.fill").foregroundStyle(WidgetPalette.purple)
                    Text("Fastest lap")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(fastest.driver.code).font(Typo.code(15))
                    Text(fastest.fastestLapTime ?? "")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                        .foregroundStyle(WidgetPalette.purple)
                }
                .padding(.top, 14)
            }
        }
    }
}

// MARK: - Championship

struct ChampionshipCard: View {
    let snapshot: SeasonSnapshot
    let stats: SeasonStats
    @Environment(AppModel.self) private var model
    @Environment(\.palette) private var palette

    private var contenders: [DriverStanding] {
        let alive = snapshot.contenders
        return Array((alive.count >= 2 ? alive : Array(snapshot.driverStandings.prefix(3))).prefix(4))
    }

    var body: some View {
        Card {
            SectionTitle(title: "Drivers' championship") {
                Button("All") {
                    model.standingsSegment = .drivers
                    model.selectedTab = .standings
                }
            }
            VStack(spacing: 10) {
                ForEach(snapshot.driverStandings.prefix(5)) { standing in
                    NavigationLink(value: Route.driver(standing.driver.id)) {
                        DriverStandingRow(standing: standing, leaderPoints: snapshot.leaderPoints, season: snapshot.standingsSeason)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)

            if stats.rounds.count > 1 {
                Divider().padding(.vertical, 14)
                let series = chartSeries
                HStack {
                    PointsLegend(series: series, size: 11)
                    Spacer(minLength: 0)
                }
                PointsChart(series: series, lineWidth: 2.2)
                    .frame(height: 170)
                    .padding(.top, 8)
                Text(remainingText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
    }

    private var chartSeries: [ProgressSeries] {
        var seenTeams: Set<String> = []
        return contenders.map { standing in
            let teamId = standing.constructor?.id ?? ""
            let dashed = seenTeams.contains(teamId)
            seenTeams.insert(teamId)
            return ProgressSeries(
                id: standing.driver.id,
                label: standing.driver.code,
                color: palette.team(teamId, season: snapshot.standingsSeason),
                points: stats.progress(driver: standing.driver.id),
                emphasized: standing.position == 1,
                dashed: dashed
            )
        }
    }

    private var remainingText: String {
        let remaining = snapshot.remainingRaces.count
        guard remaining > 0 else { return "Final standings." }
        let alive = snapshot.contenders.count
        return "\(remaining) \(remaining == 1 ? "race" : "races") left with up to \(Fmt.points(snapshot.maxPointsRemaining)) points available · \(alive) \(alive == 1 ? "driver" : "drivers") can still win."
    }
}

struct DriverStandingRow: View {
    let standing: DriverStanding
    let leaderPoints: Double
    let season: Int
    @Environment(\.palette) private var palette

    var body: some View {
        let color = palette.team(standing.constructor?.id, season: season)
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                PositionBadge(position: standing.position, size: 24)
                TeamStripe(color: color, width: 4, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(Flags.nationality(standing.driver.nationality)).font(.footnote)
                        Text(standing.driver.familyName)
                            .font(.body.weight(.semibold))
                            .lineLimit(1)
                    }
                    Text(standing.constructor.map(TeamPalette.shortName) ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(Fmt.points(standing.points))
                        .font(Typo.number(17, weight: .heavy))
                    if standing.wins > 0 {
                        Text("\(standing.wins) \(standing.wins == 1 ? "win" : "wins")")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            PointsBar(fraction: leaderPoints > 0 ? standing.points / leaderPoints : 0, color: color, height: 4)
                .padding(.leading, 48)
        }
        .contentShape(Rectangle())
    }
}

struct ConstructorStandingRow: View {
    let standing: ConstructorStanding
    let leaderPoints: Double
    let drivers: [DriverStanding]
    let season: Int
    @Environment(\.palette) private var palette

    var body: some View {
        let color = palette.team(standing.constructor.id, season: season)
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                PositionBadge(position: standing.position, size: 24)
                TeamStripe(color: color, width: 4, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(TeamPalette.shortName(for: standing.constructor))
                        .font(.body.weight(.semibold))
                    Text(drivers.prefix(3).map(\.driver.familyName).joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text(Fmt.points(standing.points))
                        .font(Typo.number(17, weight: .heavy))
                    if standing.wins > 0 {
                        Text("\(standing.wins) \(standing.wins == 1 ? "win" : "wins")")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            PointsBar(fraction: leaderPoints > 0 ? standing.points / leaderPoints : 0, color: color, height: 4)
                .padding(.leading, 48)
        }
        .contentShape(Rectangle())
    }
}

struct ConstructorsCard: View {
    let snapshot: SeasonSnapshot
    @Environment(AppModel.self) private var model

    var body: some View {
        Card {
            SectionTitle(title: "Constructors") {
                Button("All") {
                    model.standingsSegment = .constructors
                    model.selectedTab = .standings
                }
            }
            VStack(spacing: 10) {
                ForEach(snapshot.constructorStandings.prefix(5)) { standing in
                    NavigationLink(value: Route.team(standing.constructor.id)) {
                        ConstructorStandingRow(
                            standing: standing,
                            leaderPoints: snapshot.constructorLeaderPoints,
                            drivers: snapshot.drivers(of: standing.constructor.id),
                            season: snapshot.standingsSeason
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 12)
        }
    }
}

/// Resolves navigation routes shared by every tab.
struct RouteView: View {
    let route: Route

    var body: some View {
        switch route {
        case .driver(let id, let season): DriverDetailView(driverId: id, season: season)
        case .team(let id, let season): TeamDetailView(constructorId: id, season: season)
        case .race(let season, let round): RaceDetailView(season: season, round: round)
        }
    }
}
