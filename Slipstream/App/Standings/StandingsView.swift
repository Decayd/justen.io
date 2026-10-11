import SwiftUI

/// Loads the snapshot for a season (current or archived) and renders content with it.
struct SeasonContent<Content: View>: View {
    let season: Int?
    @ViewBuilder let content: (SeasonSnapshot, SeasonStats) -> Content
    @Environment(AppModel.self) private var model
    @State private var loaded: (snapshot: SeasonSnapshot, stats: SeasonStats)?
    @State private var error: String?

    private var needsArchive: Bool {
        guard let season else { return false }
        return season != model.snapshot?.standingsSeason
    }

    var body: some View {
        if needsArchive, let season {
            if let loaded, loaded.snapshot.standingsSeason == season {
                content(loaded.snapshot, loaded.stats)
            } else if let error {
                ContentUnavailableView("Couldn't load \(String(season))", systemImage: "wifi.exclamationmark", description: Text(error))
            } else {
                ProgressView("Loading \(String(season))…")
                    .frame(maxWidth: .infinity, minHeight: 300)
                    .task(id: season) { await load(season) }
            }
        } else if let snapshot = model.snapshot, let stats = model.stats {
            content(snapshot, stats)
        } else {
            LoadingState()
        }
    }

    private func load(_ season: Int) async {
        do {
            let snapshot = try await model.season(season)
            loaded = (snapshot, SeasonStats(snapshot: snapshot))
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct StandingsView: View {
    @Environment(AppModel.self) private var model
    @State private var season: Int?

    private var currentSeason: Int {
        model.snapshot?.standingsSeason ?? Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.standingsPath) {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Championship", selection: $model.standingsSegment) {
                        ForEach(StandingsSegment.allCases) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)

                    SeasonContent(season: season) { snapshot, stats in
                        StandingsTable(snapshot: snapshot, stats: stats, segment: model.standingsSegment, archived: season != nil)
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(String(season ?? currentSeason)) Standings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Season", selection: $season) {
                            Text("Current season").tag(Int?.none)
                            ForEach((1950..<currentSeason).reversed(), id: \.self) { year in
                                Text(String(year)).tag(Int?.some(year))
                            }
                        }
                    } label: {
                        Label("Season", systemImage: "calendar.badge.clock")
                    }
                }
            }
            .refreshable { await model.refresh(force: true) }
            .navigationDestination(for: Route.self) { RouteView(route: $0) }
        }
    }
}

private struct StandingsTable: View {
    let snapshot: SeasonSnapshot
    let stats: SeasonStats
    let segment: StandingsSegment
    let archived: Bool

    private var subtitle: String {
        if let race = snapshot.standingsRace(round: snapshot.standingsRound) {
            let state = snapshot.remainingRaces.isEmpty ? "Final standings" : "After round \(snapshot.standingsRound)"
            return "\(state) · \(race.name)"
        }
        return "Round \(snapshot.standingsRound)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            Card(padding: 14) {
                VStack(spacing: 12) {
                    switch segment {
                    case .drivers:
                        ForEach(snapshot.driverStandings) { standing in
                            NavigationLink(value: Route.driver(standing.driver.id, season: archived ? snapshot.standingsSeason : nil)) {
                                DriverStandingRow(standing: standing, leaderPoints: snapshot.leaderPoints, season: snapshot.standingsSeason)
                            }
                            .buttonStyle(.plain)
                        }
                    case .constructors:
                        if snapshot.constructorStandings.isEmpty {
                            Text("The constructors' championship began in 1958.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        ForEach(snapshot.constructorStandings) { standing in
                            NavigationLink(value: Route.team(standing.constructor.id, season: archived ? snapshot.standingsSeason : nil)) {
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
                }
            }
            DataFooter()
        }
    }
}
