import SwiftUI

struct CalendarView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        NavigationStack(path: $model.calendarPath) {
            ScrollView {
                VStack(spacing: 18) {
                    if let snapshot = model.snapshot {
                        CalendarContent(snapshot: snapshot)
                    } else {
                        LoadingState()
                    }
                    DataFooter()
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(model.snapshot.map { "\(String($0.season)) Calendar" } ?? "Calendar")
            .refreshable { await model.refresh(force: true) }
            .navigationDestination(for: Route.self) { RouteView(route: $0) }
        }
    }
}

private struct CalendarContent: View {
    let snapshot: SeasonSnapshot

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            let now = timeline.date
            let upcoming = snapshot.races.filter { $0.end > now }
            let completed = snapshot.races.filter { $0.end <= now }.reversed()

            VStack(spacing: 18) {
                SeasonProgressHeader(completed: completed.count, total: snapshot.races.count, sprints: snapshot.races.filter(\.isSprintWeekend).count)

                if let next = upcoming.first {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("Up next")
                        NavigationLink(value: Route.race(season: next.season, round: next.round)) {
                            NextRaceHero(snapshot: snapshot, race: next)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if upcoming.count > 1 {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("Upcoming")
                        Card(padding: 0) {
                            ForEach(Array(upcoming.dropFirst().enumerated()), id: \.offset) { index, race in
                                NavigationLink(value: Route.race(season: race.season, round: race.round)) {
                                    RaceRow(race: race, winner: nil, now: now)
                                }
                                .buttonStyle(.plain)
                                if index < upcoming.count - 2 { Divider().padding(.leading, 64) }
                            }
                        }
                    }
                }

                if !completed.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionTitle("Completed")
                        Card(padding: 0) {
                            ForEach(Array(completed.enumerated()), id: \.offset) { index, race in
                                NavigationLink(value: Route.race(season: race.season, round: race.round)) {
                                    RaceRow(race: race, winner: winner(for: race), now: now)
                                }
                                .buttonStyle(.plain)
                                if index < completed.count - 1 { Divider().padding(.leading, 64) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func winner(for race: Race) -> RaceResult? {
        guard race.season == snapshot.standingsSeason else { return nil }
        return snapshot.results(round: race.round)?.winner
    }
}

private struct SeasonProgressHeader: View {
    let completed: Int
    let total: Int
    let sprints: Int

    var body: some View {
        Card {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(completed) of \(total)")
                        .font(Typo.display(22, weight: .heavy))
                    Text("ROUNDS COMPLETE")
                        .font(Typo.label(9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(sprints)")
                        .font(Typo.display(22, weight: .heavy))
                    Text("SPRINT WEEKENDS")
                        .font(Typo.label(9, weight: .bold))
                        .foregroundStyle(.secondary)
                }
            }
            SeasonProgressBar(completed: completed, total: total)
                .padding(.top, 14)
        }
    }
}

private struct RaceRow: View {
    let race: Race
    let winner: RaceResult?
    let now: Date
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 0) {
                Text("R\(race.round)")
                    .font(Typo.number(11, weight: .heavy))
                    .foregroundStyle(.secondary)
                Text(Flags.country(race.circuit.country))
                    .font(.title2)
            }
            .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(race.shortName)
                        .font(.body.weight(.semibold))
                    if race.isSprintWeekend { SprintBadge() }
                }
                Text("\(race.circuit.locality) · \(Fmt.weekend(race))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            if let winner {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.gold)
                    TeamStripe(color: palette.team(winner.constructor?.id, season: race.season), width: 3, height: 16)
                    Text(winner.driver.code)
                        .font(Typo.code(15))
                }
            } else if let next = race.nextSession(after: now), race.weekendStart.timeIntervalSince(now) < 14 * 86_400 {
                Text(Countdown(now: now, session: next).compact)
                    .font(Typo.number(13, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
